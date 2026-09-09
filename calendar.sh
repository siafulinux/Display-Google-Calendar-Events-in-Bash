```bash
#!/usr/bin/env bash

# ==============================================================================
# Google Calendar CLI
# ==============================================================================
#
# A lightweight terminal viewer for Google Calendar.
#
# Displays:
#   - Today's events
#   - Events for the current Monday-Sunday week
#   - Timed and all-day events
#
# Requirements:
#   - bash
#   - curl
#   - jq
#   - GNU coreutils (date)
#
# Configuration:
#   Create a "config" file from "example.config".
#
# Usage:
#   ./calendar.sh
#
# ==============================================================================

set -o pipefail

# ------------------------------------------------------------------------------
# Colors
# ------------------------------------------------------------------------------

if [[ -t 1 ]]; then
    RESET='\033[0m'
    BOLD='\033[1m'
    DIM='\033[2m'
    CYAN='\033[36m'
    GREEN='\033[32m'
    YELLOW='\033[33m'
    BLUE='\033[34m'
    RED='\033[31m'
    WHITE='\033[97m'
else
    RESET=''
    BOLD=''
    DIM=''
    CYAN=''
    GREEN=''
    YELLOW=''
    BLUE=''
    RED=''
    WHITE=''
fi

# ------------------------------------------------------------------------------
# Locate script directory
# ------------------------------------------------------------------------------

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="${SCRIPT_DIR}/config"

# ------------------------------------------------------------------------------
# Load configuration
# ------------------------------------------------------------------------------

if [[ ! -f "$CONFIG_FILE" ]]; then
    echo -e "${RED}Error:${RESET} Configuration file not found."
    echo
    echo "Create it from the example:"
    echo
    echo "    cp example.config config"
    echo
    echo "Then edit:"
    echo
    echo "    nano config"
    exit 1
fi

# shellcheck source=/dev/null
source "$CONFIG_FILE"

# ------------------------------------------------------------------------------
# Validate configuration
# ------------------------------------------------------------------------------

if [[ -z "${GOOGLE_API_KEY:-}" || "$GOOGLE_API_KEY" == "your-google-api-key-here" ]]; then
    echo -e "${RED}Error:${RESET} GOOGLE_API_KEY is not configured."
    echo
    echo "Edit:"
    echo "    $CONFIG_FILE"
    exit 1
fi

if [[ -z "${CALENDAR_ID:-}" || "$CALENDAR_ID" == "your-calendar-id-here" ]]; then
    echo -e "${RED}Error:${RESET} CALENDAR_ID is not configured."
    echo
    echo "Edit:"
    echo "    $CONFIG_FILE"
    exit 1
fi

# ------------------------------------------------------------------------------
# Check dependencies
# ------------------------------------------------------------------------------

for command in curl jq date; do
    if ! command -v "$command" >/dev/null 2>&1; then
        echo -e "${RED}Error:${RESET} Required command not found: $command"
        echo
        echo "Install the required packages with:"
        echo
        echo "    sudo apt install curl jq"
        exit 1
    fi
done

# ------------------------------------------------------------------------------
# Date calculations
# ------------------------------------------------------------------------------

TODAY="$(date -u +%Y-%m-%d)"
TODAY_DISPLAY="$(date -u +"%A, %B %d, %Y")"

WEEK_START="$(date -u -d 'monday this week' +%Y-%m-%d)"
WEEK_END="$(date -u -d 'monday this week + 6 days' +%Y-%m-%d)"

WEEK_START_DISPLAY="$(date -u -d "$WEEK_START" +"%B %d, %Y")"
WEEK_END_DISPLAY="$(date -u -d "$WEEK_END" +"%B %d, %Y")"

WEEK_START_ISO="${WEEK_START}T00:00:00Z"
WEEK_END_ISO="$(date -u -d "$WEEK_END + 1 day" +%Y-%m-%d)T00:00:00Z"

# ------------------------------------------------------------------------------
# URL encode calendar ID
# ------------------------------------------------------------------------------

ENCODED_CALENDAR_ID="$(jq -rn --arg value "$CALENDAR_ID" '$value | @uri')"

API_URL="https://www.googleapis.com/calendar/v3/calendars/${ENCODED_CALENDAR_ID}/events"

# ------------------------------------------------------------------------------
# Display helpers
# ------------------------------------------------------------------------------

print_rule() {
    printf '%s\n' "${DIM}────────────────────────────────────────────────────────────${RESET}"
}

print_header() {
    echo
    echo -e "${BOLD}${CYAN}Google Calendar${RESET}"
    echo -e "${DIM}${TODAY_DISPLAY}${RESET}"
    print_rule
}

format_time() {
    local datetime="$1"

    if [[ "$datetime" == *T* ]]; then
        date -u -d "$datetime" +"%H:%M"
    else
        echo "All Day"
    fi
}

format_date() {
    local date_value="$1"
    date -u -d "$date_value" +"%A, %B %d"
}

# ------------------------------------------------------------------------------
# Retrieve events
# ------------------------------------------------------------------------------

RESPONSE="$(
    curl \
        --silent \
        --show-error \
        --fail-with-body \
        --get \
        --url "$API_URL" \
        --header "Accept: application/json" \
        --data-urlencode "key=${GOOGLE_API_KEY}" \
        --data-urlencode "timeMin=${WEEK_START_ISO}" \
        --data-urlencode "timeMax=${WEEK_END_ISO}" \
        --data-urlencode "singleEvents=true" \
        --data-urlencode "orderBy=startTime" \
        --data-urlencode "fields=items(summary,start,end)"
)"

CURL_STATUS=$?

if [[ $CURL_STATUS -ne 0 ]]; then
    echo -e "${RED}Error:${RESET} Unable to retrieve Google Calendar events."
    echo
    printf '%s\n' "$RESPONSE"
    exit 1
fi

# ------------------------------------------------------------------------------
# Validate response
# ------------------------------------------------------------------------------

if ! jq empty >/dev/null 2>&1 <<< "$RESPONSE"; then
    echo -e "${RED}Error:${RESET} Google Calendar returned invalid JSON."
    exit 1
fi

# ------------------------------------------------------------------------------
# Today's events
# ------------------------------------------------------------------------------

TODAY_EVENTS="$(
    jq -c --arg today "$TODAY" '
        [
            .items[]
            | select(
                ((.start.dateTime // .start.date) | startswith($today))
            )
        ]
    ' <<< "$RESPONSE"
)"

TODAY_COUNT="$(jq 'length' <<< "$TODAY_EVENTS")"

# ------------------------------------------------------------------------------
# Header
# ------------------------------------------------------------------------------

print_header

# ------------------------------------------------------------------------------
# Today's events
# ------------------------------------------------------------------------------

echo
echo -e "${BOLD}${WHITE}TODAY${RESET}"
echo

if [[ "$TODAY_COUNT" -eq 0 ]]; then
    echo -e "  ${DIM}No events scheduled for today.${RESET}"
else

    while IFS=$'\t' read -r summary start_time end_time; do

        start_formatted="$(format_time "$start_time")"
        end_formatted="$(format_time "$end_time")"

        if [[ "$start_formatted" == "All Day" ]]; then
            echo -e "  ${GREEN}All Day${RESET}  ${summary}"
        else
            echo -e "  ${CYAN}${start_formatted}${RESET} - ${CYAN}${end_formatted}${RESET}  ${summary}"
        fi

    done < <(
        jq -r '
            .[]
            | [
                (.summary // "(No title)"),
                (.start.dateTime // .start.date),
                (.end.dateTime // .end.date)
              ]
            | @tsv
        ' <<< "$TODAY_EVENTS"
    )
fi

# ------------------------------------------------------------------------------
# This week's events
# ------------------------------------------------------------------------------

echo
print_rule
echo
echo -e "${BOLD}${WHITE}THIS WEEK${RESET}"
echo -e "${DIM}${WEEK_START_DISPLAY} - ${WEEK_END_DISPLAY}${RESET}"

echo

WEEK_COUNT="$(jq '.items | length' <<< "$RESPONSE")"

if [[ "$WEEK_COUNT" -eq 0 ]]; then

    echo -e "  ${DIM}No events scheduled this week.${RESET}"

else

    CURRENT_DAY=""

    while IFS=$'\t' read -r summary start_time end_time; do

        # Determine event date.
        if [[ "$start_time" == *T* ]]; then
            EVENT_DATE="${start_time%%T*}"
        else
            EVENT_DATE="$start_time"
        fi

        # New day heading.
        if [[ "$EVENT_DATE" != "$CURRENT_DAY" ]]; then

            if [[ -n "$CURRENT_DAY" ]]; then
                echo
            fi

            echo -e "${BOLD}${BLUE}$(format_date "$EVENT_DATE")${RESET}"
            echo -e "${DIM}────────────────────────────────────────${RESET}"

            CURRENT_DAY="$EVENT_DATE"
        fi

        start_formatted="$(format_time "$start_time")"
        end_formatted="$(format_time "$end_time")"

        if [[ "$start_formatted" == "All Day" ]]; then

            echo -e "  ${GREEN}All Day${RESET}  ${summary}"

        else

            echo -e "  ${CYAN}${start_formatted}${RESET} - ${CYAN}${end_formatted}${RESET}  ${summary}"

        fi

    done < <(
        jq -r '
            .items[]
            | [
                (.summary // "(No title)"),
                (.start.dateTime // .start.date),
                (.end.dateTime // .end.date)
              ]
            | @tsv
        ' <<< "$RESPONSE"
    )
fi

# ------------------------------------------------------------------------------
# Footer
# ------------------------------------------------------------------------------

echo
print_rule
echo -e "${DIM}Calendar ID: ${CALENDAR_ID}${RESET}"
echo
```
