# IP ADDRESSES
export APP_CATCOIN_NODE_IP="10.21.21.8"
export APP_CATCOIN_TOR_PROXY_IP="10.21.22.10"
export APP_CATCOIN_I2P_DAEMON_IP="10.21.22.11"

# DATA DIR
export APP_CATCOIN_DATA_DIR="${EXPORTS_APP_DIR}/data/catcoin"

# PORTS
export APP_CATCOIN_RPC_PORT="8332"
export APP_CATCOIN_P2P_PORT="8333"
# Additional inbound P2P listener granting whitelisted permissions (whitebind) to this port; for trusted internal apps only; do not publish externally
export APP_CATCOIN_P2P_WHITEBIND_PORT="8335"
# As of v28.1, the default onion listening port will now be derived to be -port + 1 instead of being set to a fixed value (8334 on mainnet)
# We are fine because we always hardcode port to 8333 regardless of network
export APP_CATCOIN_TOR_PORT="8334"
export APP_CATCOIN_ZMQ_RAWBLOCK_PORT="28332"
export APP_CATCOIN_ZMQ_RAWTX_PORT="28333"
export APP_CATCOIN_ZMQ_HASHBLOCK_PORT="28334"
export APP_CATCOIN_ZMQ_SEQUENCE_PORT="28335"
export APP_CATCOIN_ZMQ_HASHTX_PORT="28336"

# NETWORK
export APP_CATCOIN_NETWORK="mainnet" 

# Check for an existing settings.json file to override APP_CATCOIN_NETWORK with user's choice
{
	CATCOIN_APP_CONFIG_FILE="${EXPORTS_APP_DIR}/data/app/settings.json"
	if [[ -f "${CATCOIN_APP_CONFIG_FILE}" ]]
	then
		catcoin_app_network=$(jq -r '.chain' "${CATCOIN_APP_CONFIG_FILE}")
		case $catcoin_app_network in
			"main")
				APP_CATCOIN_NETWORK="mainnet";;
			"test")
				APP_CATCOIN_NETWORK="testnet";;
			"testnet4")
				APP_CATCOIN_NETWORK="testnet4";;
			"signet")
				APP_CATCOIN_NETWORK="signet";;
			"regtest")
				APP_CATCOIN_NETWORK="regtest";;
			*)
				if [[ -n "$catcoin_app_network" ]] && [[ "$catcoin_app_network" != "null" ]]; then
					echo "Warning (${EXPORTS_APP_ID}): Invalid network '${catcoin_app_network}' in settings.json. Exporting APP_CATCOIN_NETWORK as default 'mainnet'."
				fi;;
		esac
	fi
} > /dev/null || true

# .env file to persist the rpc username and password
CATCOIN_ENV_FILE="${EXPORTS_APP_DIR}/.env"

# If no .env file exists, create one with generated values
if [[ ! -f "${CATCOIN_ENV_FILE}" ]]; then
	if [[ -z ${CATCOIN_RPC_USER+x} ]] || [[ -z ${CATCOIN_RPC_PASS+x} ]]; then
		CATCOIN_RPC_USER="umbrel"
		CATCOIN_RPC_DETAILS=$("${EXPORTS_APP_DIR}/scripts/rpcauth.py" "${CATCOIN_RPC_USER}")
		CATCOIN_RPC_PASS=$(echo "$CATCOIN_RPC_DETAILS" | tail -1)
	fi

	echo "export APP_CATCOIN_RPC_USER='${CATCOIN_RPC_USER}'"	>> "${CATCOIN_ENV_FILE}"
	echo "export APP_CATCOIN_RPC_PASS='${CATCOIN_RPC_PASS}'"	>> "${CATCOIN_ENV_FILE}"
fi

# Source the .env file to export APP_CATCOIN_RPC_USER and APP_CATCOIN_RPC_PASS
. "${CATCOIN_ENV_FILE}"

# HIDDEN SERVICES
rpc_hidden_service_file="${EXPORTS_TOR_DATA_DIR}/app-${EXPORTS_APP_ID}-rpc/hostname"
p2p_hidden_service_file="${EXPORTS_TOR_DATA_DIR}/app-${EXPORTS_APP_ID}-p2p/hostname"
export APP_CATCOIN_RPC_HIDDEN_SERVICE="$(cat "${rpc_hidden_service_file}" 2>/dev/null || echo "notyetset.onion")"
export APP_CATCOIN_P2P_HIDDEN_SERVICE="$(cat "${p2p_hidden_service_file}" 2>/dev/null || echo "notyetset.onion")"

# TODO: it would be nice for Electrs to handle this instead, but removing this would break existing installs of Electrs until they updated.
# Export an electrs compatible network parameter
# electrs uses "catcoin" instead of "mainnet", but matches all other test networks
export APP_CATCOIN_NETWORK_ELECTRS=$APP_CATCOIN_NETWORK
if [[ "${APP_CATCOIN_NETWORK_ELECTRS}" = "mainnet" ]]; then
	APP_CATCOIN_NETWORK_ELECTRS="catcoin"
fi
