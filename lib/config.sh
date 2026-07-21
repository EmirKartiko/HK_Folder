load_config() {
    source "$CONFIG_FILE"

    DIRECTORIES=()

    while IFS= read -r LINE
    do
        [ -n "$LINE" ] && DIRECTORIES+=("$LINE")
    done < "$DIRECTORY_FILE"

}

save_config() {

cat > "$CONFIG_FILE" <<EOF
CONFIG_VERSION=2
AGE_DAYS=$AGE_DAYS
SIZE_MB=$SIZE_MB
MODE=$MODE
EOF

printf "%s\n" "${DIRECTORIES[@]}" > "$DIRECTORY_FILE"

}

view_configuration() {

    clear

    echo "========================================="
    echo " Current Configuration"
    echo "========================================="

    echo

    printf "%-20s : %s Days\n" "Age" "$AGE_DAYS"
    printf "%-20s : %s MB\n" "Size" "$SIZE_MB"
    printf "%-20s : %s\n" "Mode" "$MODE"

    echo

    echo "Directories"

    COUNT=1

    for DIR in "${DIRECTORIES[@]}"
    do
        echo " $COUNT. $DIR"
        ((COUNT++))
    done

    echo

    read -n1 -rsp "Press any key..."

}

validate_directory() {
    local DIR="$1"

    if [ ! -d "$DIR" ]; then
        echo "Directory does not exist."
        return 1
    fi

    if [ ! -r "$DIR" ]; then
        echo "Directory is not readable."
        return 1
    fi

    for EXISTING in "${DIRECTORIES[@]}"; do
        if [ "$DIR" = "$EXISTING" ]; then
            echo "Directory already exists."
            return 1
        fi
    done

    return 0
}