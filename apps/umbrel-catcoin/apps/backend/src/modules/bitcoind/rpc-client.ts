import Client from 'bitcoin-core'

export const rpcClient = new Client({
	host: `http://${process.env['CATCOIND_IP'] || '127.0.0.1'}:${process.env['RPC_PORT'] || '9932'}`,
	username: process.env['RPC_USER'] || 'umbrel',
	password: process.env['RPC_PASS'] || 'moneyprintergobrrr',
})
