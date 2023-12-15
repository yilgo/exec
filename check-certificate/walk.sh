#!/bin/bash
if [ -n "${VAULT_ADDR}" ]; then
	if [ -z "$VAULT_TOKEN" ]; then
		if [ -s "$HOME/.vault_tokens" ]; then
			VAULT_TOKEN=$(awk -v RS= 'NR=1{gsub(/\n/, "", $1); print $1}' "$HOME/.vault_tokens")
			[[ $? ]] && export VAULT_TOKEN
		elif [ -n "$VAULT_ROLE_ID" ] && [ -n "$VAULT_SECRET_ID" ]; then
			VAULT_TOKEN=$(vault write -field=token auth/approle/login role_id="$VAULT_ROLE_ID" secret_id="$VAULT_SECRET_ID")
			[[ $? ]] && export VAULT_TOKEN
		elif [ -s "$HOME/.role_id" ] && [ -s "$HOME/.secret_id" ]; then
			role_id=$(awk -v RS= 'NR=1{gsub(/\n/, "", $1); print $1}' "$HOME/.role_id")
			secret_id=$(awk -v RS= 'NR=1{gsub(/\n/, "", $1); print $1}' "$HOME/.secret_id")
			VAULT_TOKEN=$(vault write -field=token auth/approle/login role_id="$role_id" secret_id="$secret_id")
			[[ $? ]] && export VAULT_TOKEN
		else
			echo >&2 "No more auth method to try(VAULT_TOKEN, APPROLE)"
			exit 251
		fi
	fi
else
	echo >&2 "please specify VAULT_ADDR"
	exit 252
fi

function walk() {
	_keys=$(vault kv list -format=json "${1}" | jq --raw-output '.[]')

	for _key in ${_keys}; do
		if [ "${_key:0-1}" != "/" ]; then
			echo "${1}${_key}"
		else
			walk "${1}${_key}"
		fi
	done
}

if (return 0 2>/dev/null); then
	export -f walk
	return 0
fi

# get KV type secret engines
KV_SE=$(vault secrets list -format=json | jq --raw-output '. | to_entries[] | select(.value.type == "kv")|.key')

ERR=$?

if [ "$ERR" -eq 0 ]; then
	for kv in ${KV_SE}; do
		walk "${kv}"
	done
fi
