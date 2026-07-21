find_default_directory() {

    local PROFILE="$1"

    shift

    DIRECTORIES=()

    echo
    echo "Searching $PROFILE directories..."
    echo

    for DIR in "$@"
    do

        if [ -d "$DIR" ]; then

            echo "[OK] $DIR"

            DIRECTORIES+=("$DIR")

            return 0

        else

            echo "[--] $DIR"

        fi

    done

    echo
    echo "Default directory not found."
    echo

    while true
    do

        read -rp "Enter $PROFILE directory : " DIR

        if [ -d "$DIR" ]; then

            DIRECTORIES=("$DIR")

            return 0

        fi

        echo "Directory does not exist."

    done

}

runner_profile() {

    find_default_directory \
        "GitLab Runner" \
        "/home/gitlab-runner/builds" \
        "/var/lib/gitlab-runner/builds" \
        "/home/Iul/sonar-migration-lab" \

}

logs_profile() {

    find_default_directory \
        "System Logs" \
        "/var/log"

}

journal_profile() {

    find_default_directory \
        "Journal" \
        "/var/log/journal" \
        "/run/log/journal"

}


custom_profile() {

    DIRECTORIES=()

    while true
    do

        read -rp "Directory : " DIR

        if [ -d "$DIR" ]; then

            DIRECTORIES+=("$DIR")

            return 0

        fi

        echo "Directory does not exist."

    done

}

configured_profile() {

    DIRECTORIES=()

    if [ ! -f "$DIRECTORY_FILE" ]; then

        echo
        echo "No configured directories found."
        echo

        read -n1 -rsp "Press any key..."

        return 1

    fi

    mapfile -t SAVED_DIRS < "$DIRECTORY_FILE"

    if [ ${#SAVED_DIRS[@]} -eq 0 ]; then

        echo
        echo "No configured directories found."
        echo

        read -n1 -rsp "Press any key..."

        return 1

    fi

    while true
    do

        clear

        echo "========================================="
        echo "      Configured Directories"
        echo "========================================="
        echo

        local INDEX=1

        for DIR in "${SAVED_DIRS[@]}"
        do

            echo "$INDEX. $DIR"

            ((INDEX++))

        done

        echo

        echo "$INDEX. All Directories"

        ((INDEX++))

        echo "$INDEX. Back"

        echo

        read -rp "Choice : " CHOICE

        #
        # Back
        #

        if [ "$CHOICE" -eq "$INDEX" ]; then

            return 1

        fi

        #
        # All Directories
        #

        if [ "$CHOICE" -eq $((INDEX-1)) ]; then

            DIRECTORIES=("${SAVED_DIRS[@]}")

            return 0

        fi

        #
        # Single Directory
        #

        if [ "$CHOICE" -ge 1 ] && [ "$CHOICE" -le "${#SAVED_DIRS[@]}" ]; then

            DIRECTORIES=("${SAVED_DIRS[$((CHOICE-1))]}")

            return 0

        fi

        echo

        echo "Invalid choice."

        sleep 1

    done

}