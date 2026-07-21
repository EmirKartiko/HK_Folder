#!/bin/bash

line() {

    printf '=%.0s' {1..70}
    echo

}

header() {

    clear

    line

    printf "%35s\n" "$1"

    line

}

pause() {

    echo

    read -n1 -rsp "Fuck it ? Press any key to continue..."

}

human_size() {

    if command -v numfmt >/dev/null
    then

        numfmt --to=iec --suffix=B "$1"

    else

        echo "$1 Bytes"

    fi

}

confirm() {

    local PROMPT="$1"

    read -rp "$PROMPT [Y/n]: " ANSWER

    ANSWER=${ANSWER:-Y}

    case "$ANSWER" in

        Y|y|YES|yes)
            return 0
            ;;

        *)
            return 1
            ;;

    esac

}

timestamp() {

    date "+%Y-%m-%d %H:%M:%S"

}

print_info() {

    echo "[INFO] $1"

}

print_error() {

    echo "[ERROR] $1"

}

print_success() {

    echo "[OK] $1"

}

show_spinner() {

    local SPIN='|/-\'
    local i=$((TOTAL_SCANNED % 4))

    printf "\r[%c] Files scanned : %'d" \
        "${SPIN:$i:1}" \
        "$TOTAL_SCANNED"

}