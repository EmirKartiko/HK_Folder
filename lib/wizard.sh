setup_wizard() {

    clear

    echo "========================================="
    echo "      HK Folder Manager v2.0"
    echo "========================================="
    echo
    echo "No configuration found."
    echo "Starting first-time setup..."
    echo

    get_age

    get_size

    get_mode

    get_directories

    show_summary

    confirm_save

    echo

    echo "Setup completed."

    sleep 2

    load_config

    main_menu

}

get_age() {

    while true; do

        read -rp "Delete files older than (days) [30]: " AGE_DAYS

        AGE_DAYS=${AGE_DAYS:-30}

        if [[ "$AGE_DAYS" =~ ^[0-9]+$ ]] && [ "$AGE_DAYS" -gt 0 ]; then
            break
        fi

        echo "Please enter a valid number."

    done

}

get_size() {

    while true; do

        read -rp "Delete files larger than (MB) [500]: " SIZE_MB

        SIZE_MB=${SIZE_MB:-500}

        if [[ "$SIZE_MB" =~ ^[0-9]+$ ]] && [ "$SIZE_MB" -gt 0 ]; then
            break
        fi

        echo "Please enter a valid number."

    done

}

get_mode() {

    while true; do

        echo
        echo "Deletion Mode"
        echo
        echo "1. AND"
        echo "2. OR"

        read -rp "Choice [1]: " MODE

        MODE=${MODE:-1}

        case "$MODE" in
            1)
                MODE="AND"
                break
                ;;
            2)
                MODE="OR"
                break
                ;;
            *)
                echo "Invalid choice."
                ;;
        esac

    done

}

get_directories() {

    DIRECTORIES=()

    echo
    echo "Enter directories to monitor."
    echo "Press ENTER without typing anything when finished."
    echo

    while true
    do

        read -rp "Directory: " DIR

        # selesai input
        [ -z "$DIR" ] && break

        # cek ada atau tidak
        if [ ! -d "$DIR" ]; then
            echo "Directory does not exist."
            continue
        fi

        # cek permission
        if [ ! -r "$DIR" ]; then
            echo "Directory is not readable."
            continue
        fi

        # cek duplicate
        DUPLICATE=0

        for EXISTING in "${DIRECTORIES[@]}"
        do
            if [ "$EXISTING" = "$DIR" ]; then
                DUPLICATE=1
                break
            fi
        done

        if [ "$DUPLICATE" -eq 1 ]; then
            echo "Directory already added."
            continue
        fi

        DIRECTORIES+=("$DIR")

        echo "✓ Added"

    done

    # minimal harus ada satu directory
    if [ ${#DIRECTORIES[@]} -eq 0 ]; then
        echo
        echo "At least one directory is required."
        echo
        get_directories
    fi

}

show_summary() {

    clear

    echo "========================================="
    echo "      Configuration Summary"
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
    echo "========================================="

}

confirm_save() {

    echo

    read -rp "Save configuration? [Y/n]: " ANSWER

    ANSWER=${ANSWER:-Y}

    case "$ANSWER" in
        Y|y|YES|yes)
            save_config
            echo
            echo "Configuration saved."
            ;;
        *)
            echo
            echo "Configuration discarded."
            exit 0
            ;;
    esac

}

