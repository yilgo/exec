#!/bin/bash

# Please respect following variables.
#-----------------------------------------
# SLACK_ICON_EMOJI
# SLACK USER
# SLACK_MESSAGE
# SLACK_CHANNEL
#-----------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"

declare -F http_req >/dev/null || source "${SCRIPT_DIR}/http.sh"

function slack_notify() {
    SLACK_ICON_EMOJI="${SLACK_ICON_EMOJI:-:slack:}"
    SLACK_USER="${SLACK_USER:-default}"
    [[ -n $SLACK_CHANNEL ]] && SLACK_CHANNEL=$(printf "{\"channel\": \"#%s\"" $SLACK_CHANNEL) || SLACK_CHANNEL="{}"
    HTTP_HEADERS="Content-type: application/json"
    HTTP_POST_DATA=$(echo | jq --null-input -R \
        --arg text "$SLACK_MESSAGE" \
        --arg emoji "$SLACK_ICON_EMOJI" \
        --arg user "$SLACK_USER" \
        --argjson ch "$SLACK_CHANNEL" \
        '{"text": $text, "username": $user, "icon_emoji": $emoji }' + $ch)
    ERR=$?
    if [ $ERR -eq 0 ] && [ -n "$SLACK_MESSAGE" ]; then
        echo "sending..."
        http_req "$1"
    else
        echo >&2 "please set SLACK_MESSAGE"
    fi
}

if (return 0 2>/dev/null); then
    export -f slack_notify
    return 0
fi

if [ $# -lt 1 ]; then
    cat <<-EOF >&2
        Please specify Slack webhook url
		usage: $0 CURL OPTS webhookurl
	EOF
    exit 253
else
    slack_notify "$1"
fi
