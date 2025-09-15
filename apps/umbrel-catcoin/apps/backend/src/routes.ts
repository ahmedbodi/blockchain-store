import {randomBytes} from 'node:crypto'

import fp from 'fastify-plugin'
import type {FastifyError, FastifyInstance} from 'fastify'
import {ZodError} from 'zod'

import * as bitcoind from './modules/bitcoind/bitcoind.js'
import * as peers from './modules/peers/peers.js'
import * as blocks from './modules/blocks/blocks.js'
import * as transactions from './modules/transactions/transactions.js'
import * as sync from './modules/sync/sync.js'
import * as stats from './modules/stats/stats.js'
import * as connect from './modules/connect/connect.js'
import * as config from './modules/config/config.js'
import * as widgets from './modules/widgets/widgets.js'

import {settingsSchema} from '#settings'

const WS_TOKEN = randomBytes(16).toString('hex')

// We attach a global error handler for all routes (see bottom of this file)
export default fp(async (app: FastifyInstance) => {
	const BASE = '/api'

	// bitcoind manager routes
	const bitcoindBase = `${BASE}/catcoind`

	app.get(`${bitcoindBase}/version`, bitcoind.version)
	app.get(`${bitcoindBase}/status`, bitcoind.status)
	// app.post(`${bitcoindBase}/start`, bitcoind.start)
	// app.post(`${bitcoindBase}/stop`, bitcoind.stop)
	// app.post(`${bitcoindBase}/restart`, bitcoind.restart)
	app.get(`${bitcoindBase}/exit-info`, bitcoind.exitInfo)

	// rpc routes
	const rpcBase = `${BASE}/rpc`

	app.get(`${rpcBase}/sync`, sync.syncStatus)

	app.get(`${rpcBase}/stats`, stats.summary)

	app.get(`${rpcBase}/peers/info`, peers.peerInfo)
	app.get(`${rpcBase}/peers/count`, peers.peerCount)
	app.get(`${rpcBase}/peers/locations`, peers.peerLocations)

	app.get<{Querystring: {limit?: number}}>(`${rpcBase}/blocks`, (req) => blocks.list(req.query.limit))
	app.get<{Querystring: {limit?: number}}>(`${rpcBase}/blocks/rewards`, (req) => blocks.rewards(req.query.limit))
	app.get<{Querystring: {limit?: number}}>(`${rpcBase}/blocks/size`, (req) => blocks.blockSizes(req.query.limit))
	app.get<{Querystring: {limit?: number}}>(`${rpcBase}/blocks/fees`, (req) => blocks.feeRates(req.query.limit))

	// connect routes
	const connectBase = `${BASE}/connect`
	app.get(`${connectBase}/details`, connect.getConnectionDetails)

	// config routes
	const configBase = `${BASE}/config`

	app.get(`${configBase}/settings`, config.getSettings)

	app.patch(`${configBase}/settings`, async (req) => {
		// We create a new Zod schema whose keys are all optional
		// and validate+coerce the incoming JSON against it.
		// This allows us to patch only the fields we want to change.
		// This will throw ZodError, which Fastify converts to 400 JSON automatically.
		const settingsChanges = settingsSchema.partial().parse(req.body)

		return config.updateSettings(settingsChanges)
	})

	app.post(`${configBase}/restore-defaults`, config.restoreDefaults)

	app.get(`${configBase}/custom-options`, async () => ({
		lines: await config.getCustomOptions(),
	}))

	app.patch(`${configBase}/custom-options`, async (req) => {
		const {lines = ''} = req.body as {lines?: string}
		const savedLines = await config.updateCustomOptions(lines)
		return {lines: savedLines}
	})

	// umbrelOS widget routes
	const widgetBase = `${BASE}/widget`

	app.get(`${widgetBase}/stats`, widgets.stats)
	app.get(`${widgetBase}/sync`, widgets.sync)

	// websocket routes
	// Note: Fastify-Websocket plugin must already be registered via app.register(fastifyWs)
	const wsBase = `${BASE}/ws`

	// Return the CSRF token (this will be unreadable cross origin due to CORS)
	app.get(`${wsBase}/token`, (request, reply) => reply.send({token: WS_TOKEN}))

	// Check CSRF token for websocket requests
	app.addHook('preValidation', async (request, reply) => {
		// Skip if not a websocket upgrade
		if (request.headers.upgrade?.toLowerCase() !== 'websocket') return

		// Check token
		if ((request.query as {token?: string})?.token !== WS_TOKEN) return reply.code(401).send('Unauthorized')
	})

	// new blocks from bitcoind via zmq
	app.get(`${wsBase}/blocks`, {websocket: true}, blocks.wsStream)

	// new transactions from bitcoind via zmq
	app.get(`${wsBase}/transactions`, {websocket: true}, transactions.wsStream)

	// bitcoind exit events
	app.get(`${wsBase}/catoind/exit`, {websocket: true}, bitcoind.wsExitStream)

	// Global error handler
	// Catches *all* uncaught errors from any route / hook
	// Normalises the response to `{ error: "...msg..." }`
	// – Zod → 400
	// – everything else → 500 (unless Fastify set its own status)
	app.setErrorHandler((err: FastifyError | ZodError, _req, reply): void => {
		const status =
			err instanceof ZodError
				? 400 // bad request / validation
				: (err.statusCode ?? 500) // Fastify may have set one

		let message: string

		if (err instanceof ZodError) {
			// Surface only the first validation error to keep the response concise for the tooltip
			message = err.issues[0]?.message ?? err.message
		} else {
			message = err.message || 'Internal Server Error'
		}

		reply.status(status).send({error: message})
	})
})
