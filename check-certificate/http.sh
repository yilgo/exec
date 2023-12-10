#!/bin/bash

if ! command -v curl >/dev/null; then
	echo "curl does not exist, please install it first"
fi

http_req() {
	local ERR CURL
	# delete temp files after function retruns.
	CURL=$(mktemp --suffix=curl) && trap "rm -f '${CURL}' '${CURL}.config' '${CURL}.payload'  '${CURL}.out'" RETURN

	if [ -n "${HTTP_HEADERS}" ]; then
		printf "header = \"%s\"\n" "${HTTP_HEADERS[@]}" >"${CURL}.config"
	fi

	if [ -n "${HTTP_USER}" ]; then
		printf "user = \"%s:%s\"\n" "${HTTP_USER}" "${HTTP_PASS}" >>"${CURL}.config"
	fi

	if [ -n "${HTTP_POST_DATA}" ]; then
		echo "${HTTP_POST_DATA}" >"${CURL}.payload"
	fi

	HTTP_RESPONSE=$(curl --silent --show-error --max-time 10 --write-out '%{response_code}' --config "${CURL}.config" \
		${HTTP_POST_DATA:+ --request POST -d @$CURL.payload} \
		--stderr "${CURL}.out" -o "${CURL}.out" "$@")
	ERR=$?

	if [ $ERR -eq 0 ]; then
		HTTP_CODE=$HTTP_RESPONSE
		HTTP_RESPONSE=$(cat "$CURL.out")
		#else
		# sed >&2 's/curl: \{1,\}//g' "$CURL.out"
		# HTTP_CODE=$HTTP_RESPONSE
	fi
	return $ERR
}

if (return 0 2>/dev/null); then
	export -f http_req
	return 0
fi

if [ $# -lt 1 ]; then
	echo "Usage: $0 'Options' URL"
else
	http_req "$@"
fi
