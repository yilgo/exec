#!/bin/bash

#declare -F get_Vault  >/dev/null || \
#	source "$(dirname "$(realpath "${BASH_SOURCE[0]}"))"/vault

export VAULT_ADDR="http://vault:8200"
export VAULT_TOKEN="s.SJoF5FmI2941GI5Bh3um69g8"

if [ -z "${VAULT_TOKEN}" ] || [ -z "${VAULT_ADDR}" ]; then
	echo "VAULT_TOKEN and VAULT_ADDR must be specified."
	exit 253
fi

function walk {
	_keys=$(vault kv list -format=json "${1}" | jq --raw-output '.[]')

	for _key in ${_keys}; do
		if [ "${_key:0-1}" != "/" ]; then
			echo "${1}${_key}"
		else
			walk "${1}${_key}"
		fi
	done
}

# if return 0 2>/dev/null ; then
# 	export -f send
# 	return 0
# fi

if return 0 2>/dev/null; then
	export -f walk
	return 0
fi

# _kv_secrets=$(vault secrets list -format=json | jq --raw-output '. | to_entries[] | select(.value.type == "kv")|.key')

#for _kv in ${_kv_secrets}; do
#	walk "${_kv}"
#done
