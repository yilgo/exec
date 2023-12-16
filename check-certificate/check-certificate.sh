#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"

declare -F fetch_from_vault >/dev/null || source "${SCRIPT_DIR}/vault.sh"

declare -F fetch_from_vault >/dev/null || source "${SCRIPT_DIR}/slack.sh"

SLACK_WEBHOOK="https://hooks.slack.com/services/BBB/AAA/XXX"

DEFAULT_TLS_THRESHOLD=30 # 30 days

message=""

function help() {
	cat <<-EOF >&2
		usage: $0 <configfile>
	EOF
	exit 253
}

if [ -z "$1" ]; then
	help
fi

if [ ! -f "${1}" ]; then
	echo >&2 "no such config file ${1} in the specified location."
	exit 252
fi

# SOURCE DOMAIN ENDDATA REMAININ DAYS
for line in $(awk '/^(tls|vault):\/\//{print $1}' "${1}"); do
	if [[ "${line}" =~ ^tls:\/\/.* ]]; then
		PORT=$(echo "${line}" | awk -F: '{print $3}')
		if [ -z "${PORT}" ]; then
			echo "[ERROR] port is not specified"
			continue
		fi
		SOURCE="tls"
		SNI=$(echo "${line}" | sed -e 's/^tls:\/\///' -e 's/:.*//') # host
		DOMAIN=$(echo "${line}" | grep -Po "(?<=tls:\/\/).*:\d+")   #host:port
		CERT=$(echo -n -Q | openssl s_client -servername "${SNI}" -connect "${DOMAIN}" 2>/dev/null |
			sed -n '/-BEGIN CERTIFICATE-/,/-END CERTIFICATE-/{p;/-END CERTIFICATE-/q}')

	elif [[ "${line}" =~ ^vault:\/\/.* ]]; then
		# vault://vault:8200/secret/data/certs/dragon/tls
		SOURCE="vault"
		SECRET=$(echo "${line}" | grep -Po "(?<=vault:\/\/).*(?=\[)")
		CERT=$(fetch_from_hcvault "${SECRET}")
		DOMAIN=$(openssl x509 -noout -dates -subject -in <(echo "$CERT") | awk '/subject=CN = /{split($0,s,"=");gsub(/ /,"",s[3]); print s[3]}')
		# openssl x509 -noout -subject  -purpose -enddate -in c.pem
	fi

	if [ -z "$CERT" ]; then
		echo "[ERROR] $SNI could not fetch certificate"
		continue
	fi

	THRESHOLD=$(echo "${line}" | grep -Po "(?<=\[)(.*?)(?=\])" | tr -d '[:blank:]')
	NOTAFTER=$(openssl x509 -noout -dates -in <(echo "$CERT") | awk '/notAfter=/{split($0,s,"=");print s[2]}')
	NOTAFTER_EPOC=$(date -d "${NOTAFTER}" +'%s')
	if [[ "${THRESHOLD:0-1}" == "d" ]]; then
		THRESHOLD="$((${THRESHOLD:0:-1}))"
	elif [[ "${THRESHOLD:0-1}" == "m" ]]; then
		THRESHOLD="$((${THRESHOLD:0:-1} * 30))"
	else
		THRESHOLD="${THRESHOLD:=$DEFAULT_TLS_THRESHOLD}"
	fi
	diff=$((("${NOTAFTER_EPOC}" - $(date '+%s')) / 86400))

	if [ "${diff}" -lt "${THRESHOLD}" ]; then
		message+=$(echo "${SOURCE}\t${DOMAIN}\t${diff}\t${THRESHOLD}\n")
	fi
done

if [ -n "$message" ]; then
	message=$(echo -e "${message}" | column --table --table-columns SOURCE,SNI,NUMBEROFDAYSTOEXPIRE,THRESHOLD)
	SLACK_MESSAGE="\`\`\`$message\`\`\`"
	slack_notify "$SLACK_WEBHOOK"
fi
