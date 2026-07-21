#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

CONFIG_FILE="$SCRIPT_DIR/config.conf"
DIRECTORY_FILE="$SCRIPT_DIR/directories.list"
LOG_FILE="$SCRIPT_DIR/HK_Folder.log"
REPORT_FILE="$SCRIPT_DIR/last_report.txt"

source "$SCRIPT_DIR/lib/config.sh"
source "$SCRIPT_DIR/lib/profiles.sh"
source "$SCRIPT_DIR/lib/wizard.sh"
source "$SCRIPT_DIR/lib/menu.sh"
source "$SCRIPT_DIR/lib/scanner.sh"
source "$SCRIPT_DIR/lib/docker.sh"
source "$SCRIPT_DIR/lib/cleanup.sh"
source "$SCRIPT_DIR/lib/cleanup_runner.sh"


clear

if [ ! -f "$CONFIG_FILE" ]; then
    setup_wizard
else
    load_config
    main_menu
fi

