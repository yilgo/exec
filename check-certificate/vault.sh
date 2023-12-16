#!/bin/bash

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

declare -F http_req >/dev/null || source "${SCRIPT_DIR}/http.sh"

if [ -n "$VAULT_TOKEN" ]; then
	HTTP_HEADERS="X-Vault-Token: $VAULT_TOKEN"
elif [ -f ~/.vault_token ]; then
	HTTP_HEADERS="X-Vault-Token: $(cat ~/.vault_token)"
else
	echo "Neither Vault Token nor Approle Set."
	exit 252
fi

if [ -z "$VAULT_ADDR" ]; then
	echo >&2 "VAULT_ADDR is not set."
	exit 251
fi

#{"request_id":"2a70fd97-0b84-50c3-60ee-184853741e89","lease_id":"","renewable":false,"lease_duration":0,"data":{"data":{"test":"test123"},"metadata":{"created_time":"2023-11-27T22:02:39.177342125Z","custom_metadata":null,"deletion_time":"","destroyed":false,"version":1}},"wrap_info":null,"warnings":null,"auth":null}
#{"errors":[]}

# RESULT=$(echo $HTTP_RESPONSE | jq --raw-output '.errors//[]|.[]')
# if [ -n "$RESULT" ]; then
# 	echo "error: $RESULT"
# fi

# echo $HTTP_RESPONSE
# echo $HTTP_CODE
function fetch_from_hcvault(){
	local vaultapi key secret
	[[ "${VAULT_ADDR:0-1}" =~ "/" ]] && VAULT_ADDR="${VAULT_ADDR%/}"
	vault_api="${VAULT_ADDR}/v1"
	# delete key name from url http(s)://a/b/c ==> c
	http_req "${vault_api}/${1%/*}"
	key="${1##*/}"
	if [ "$HTTP_CODE" -eq 200 ]; then
		secret=$(echo "$HTTP_RESPONSE" | jq --raw-output --arg key "$key" '.data.data[$key]//.data[$key]//empty')
		if [ -z "$secret" ]; then
			echo "No such key: ${key}"
			return 253
		else
			echo "$secret"
		fi
	else
		echo "Error fetching vault secret: $HTTP_CODE"
		return 252
	fi
}

if (return 0 2>/dev/null); then
	export -f fetch_from_hcvault
	return 0
fi

if [ $# -lt 1 ]; then
	echo "Usage: $0 'Options' URL"
else
	fetch_from_hcvault "$@"
fi
