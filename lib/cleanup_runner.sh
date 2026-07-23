# ============================================================
# GITLAB RUNNER CLEANUP
#
# Strategy:
# - Detect actual Git projects using .git directory
# - Treat each project directory as ONE atomic cleanup unit
# - Determine age from the newest activity inside the project
# - Filter using AGE_DAYS and SIZE_MB
# - Re-check activity immediately before deletion
# - Never delete individual old files inside a project
# ============================================================


# ------------------------------------------------------------
# GLOBAL VARIABLES
# ------------------------------------------------------------

RUNNER_DIRECTORIES=()
RUNNER_PROJECTS=()
RUNNER_CANDIDATES=()

declare -A RUNNER_SCAN_MTIME
declare -A RUNNER_PROJECT_SIZE
declare -A RUNNER_PROJECT_AGE

RUNNER_DELETE_SIZE=0


# ------------------------------------------------------------
# SCAN ACTUAL GITLAB RUNNER PROJECTS
# ------------------------------------------------------------
search_runner_directories() {

    RUNNER_DIRECTORIES=()

    echo
    echo "Searching GitLab Runner directories..."
    echo

    local POSSIBLE_DIRS=(
        "/home/gitlab-runner/builds"
        "/var/lib/gitlab-runner/builds"
    )

    for DIR in "${POSSIBLE_DIRS[@]}"
    do

        if [ -d "$DIR" ]; then

            echo "[OK] $DIR"

            RUNNER_DIRECTORIES+=("$DIR")

        fi

    done

    echo

    if [ "${#RUNNER_DIRECTORIES[@]}" -eq 0 ]; then

        echo "[ERROR] No GitLab Runner build directories found."

        return 1

    fi

    return 0
}

scan_runner_projects() {

    RUNNER_PROJECTS=()

    echo
    echo "Scanning actual GitLab Runner projects..."
    echo

    for DIR in "${RUNNER_DIRECTORIES[@]}"
    do

        [ -d "$DIR" ] || continue

        while IFS= read -r GIT_DIR
        do

            [ -n "$GIT_DIR" ] || continue

            PROJECT=$(dirname "$GIT_DIR")

            #
            # Prevent duplicate entries
            #
            FOUND=0

            for EXISTING_PROJECT in "${RUNNER_PROJECTS[@]}"
            do

                if [ "$EXISTING_PROJECT" = "$PROJECT" ]; then
                    FOUND=1
                    break
                fi

            done

            if [ "$FOUND" -eq 0 ]; then
                RUNNER_PROJECTS+=("$PROJECT")
            fi

        done < <(

            find "$DIR" \
                -type d \
                -name ".git" \
                -prune \
                -print 2>/dev/null

        )

    done

    echo
    echo "Found ${#RUNNER_PROJECTS[@]} actual project(s)."
}

# ------------------------------------------------------------
# GET LAST ACTIVITY OF PROJECT
# ------------------------------------------------------------

get_project_last_activity() {

    local PROJECT="$1"
    local LAST_ACTIVITY

    #
    # Find newest modification timestamp anywhere
    # inside the project.
    #
    # This prevents parent directory timestamps from
    # being used as the project age.
    #
    LAST_ACTIVITY=$(
        find "$PROJECT" \
            -printf '%T@\n' 2>/dev/null |
        sort -nr |
        head -1
    )

    if [ -z "$LAST_ACTIVITY" ]; then
        echo "0"
        return
    fi

    #
    # find %T@ returns:
    #
    # 1784789321.1234567890
    #
    # We only need epoch seconds.
    #
    LAST_ACTIVITY=${LAST_ACTIVITY%%.*}

    echo "$LAST_ACTIVITY"

}


# ------------------------------------------------------------
# GET PROJECT SIZE
# ------------------------------------------------------------

get_project_size() {

    local PROJECT="$1"
    local SIZE

    SIZE=$(
        du -sb "$PROJECT" 2>/dev/null |
        awk '{print $1}'
    )

    if [ -z "$SIZE" ]; then
        SIZE=0
    fi

    echo "$SIZE"

}


# ------------------------------------------------------------
# HUMAN READABLE SIZE
# ------------------------------------------------------------

human_size() {

    local BYTES="$1"

    if [ "$BYTES" -ge 1073741824 ]; then

        awk -v bytes="$BYTES" \
            'BEGIN {printf "%.2f GB", bytes/1073741824}'

    elif [ "$BYTES" -ge 1048576 ]; then

        awk -v bytes="$BYTES" \
            'BEGIN {printf "%.2f MB", bytes/1048576}'

    elif [ "$BYTES" -ge 1024 ]; then

        awk -v bytes="$BYTES" \
            'BEGIN {printf "%.2f KB", bytes/1024}'

    else

        printf "%s B" "$BYTES"

    fi

}


# ------------------------------------------------------------
# FILTER PROJECTS BY AGE + SIZE
# ------------------------------------------------------------

filter_runner_projects() {

    RUNNER_CANDIDATES=()

    RUNNER_SCAN_MTIME=()
    RUNNER_PROJECT_SIZE=()
    RUNNER_PROJECT_AGE=()

    RUNNER_DELETE_SIZE=0

    local NOW
    NOW=$(date +%s)

    local SIZE_LIMIT_BYTES
    SIZE_LIMIT_BYTES=$((SIZE_MB * 1024 * 1024))

    echo

    printf "%-65s %-12s %-12s %-20s\n" \
        "Project" \
        "Age" \
        "Size" \
        "Status"

    printf "%-65s %-12s %-12s %-20s\n" \
        "-----------------------------------------------------------------" \
        "------------" \
        "------------" \
        "--------------------"

    for PROJECT in "${RUNNER_PROJECTS[@]}"
    do

        #
        # Project may disappear between scan and filter.
        #
        if [ ! -d "$PROJECT" ]; then

            printf "%-65s %-12s %-12s %-20s\n" \
                "$PROJECT" \
                "-" \
                "-" \
                "SKIP (MISSING)"

            continue

        fi


        # ----------------------------------------------------
        # LAST ACTIVITY
        # ----------------------------------------------------

        LAST_ACTIVITY=$(get_project_last_activity "$PROJECT")

        if [ "$LAST_ACTIVITY" -eq 0 ]; then

            printf "%-65s %-12s %-12s %-20s\n" \
                "$PROJECT" \
                "-" \
                "-" \
                "SKIP (NO DATA)"

            continue

        fi


        # ----------------------------------------------------
        # PROJECT AGE
        # ----------------------------------------------------

        PROJECT_AGE=$(( (NOW - LAST_ACTIVITY) / 86400 ))


        # ----------------------------------------------------
        # PROJECT SIZE
        # ----------------------------------------------------

        PROJECT_SIZE=$(get_project_size "$PROJECT")

        PROJECT_SIZE_HUMAN=$(human_size "$PROJECT_SIZE")


        # ----------------------------------------------------
        # SAVE SCAN STATE
        #
        # Used later to detect activity between scan
        # and deletion.
        # ----------------------------------------------------

        RUNNER_SCAN_MTIME["$PROJECT"]="$LAST_ACTIVITY"

        RUNNER_PROJECT_SIZE["$PROJECT"]="$PROJECT_SIZE"

        RUNNER_PROJECT_AGE["$PROJECT"]="$PROJECT_AGE"


        # ----------------------------------------------------
        # FILTER
        #
        # BOTH conditions must be true:
        #
        # AGE >= AGE_DAYS
        # SIZE >= SIZE_MB
        # ----------------------------------------------------

        if [ "$PROJECT_AGE" -lt "$AGE_DAYS" ]; then

            STATUS="KEEP (AGE)"

        elif [ "$PROJECT_SIZE" -lt "$SIZE_LIMIT_BYTES" ]; then

            STATUS="KEEP (SIZE)"

        else

            STATUS="CANDIDATE"

            RUNNER_CANDIDATES+=("$PROJECT")

            ((RUNNER_DELETE_SIZE += PROJECT_SIZE))

        fi


        printf "%-65s %-12s %-12s %-20s\n" \
            "$PROJECT" \
            "${PROJECT_AGE} days" \
            "$PROJECT_SIZE_HUMAN" \
            "$STATUS"

    done


    echo
    echo "Candidate Projects : ${#RUNNER_CANDIDATES[@]}"
    echo "Estimated Cleanup  : $(human_size "$RUNNER_DELETE_SIZE")"

}


# ------------------------------------------------------------
# CALCULATE RUNNER SIZE
#
# Kept as separate function for compatibility with
# existing runner_profile flow.
# ------------------------------------------------------------

calculate_runner_size() {

    RUNNER_DELETE_SIZE=0

    for PROJECT in "${RUNNER_CANDIDATES[@]}"
    do

        if [ -n "${RUNNER_PROJECT_SIZE[$PROJECT]+x}" ]; then

            SIZE="${RUNNER_PROJECT_SIZE[$PROJECT]}"

        else

            SIZE=$(get_project_size "$PROJECT")

        fi

        ((RUNNER_DELETE_SIZE += SIZE))

    done

}


# ------------------------------------------------------------
# CONFIRM CLEANUP
# ------------------------------------------------------------

confirm_runner_cleanup() {

    if [ "${#RUNNER_CANDIDATES[@]}" -eq 0 ]; then

        echo
        echo "No candidate projects found."

        return 1

    fi

    echo
    echo "Projects to delete : ${#RUNNER_CANDIDATES[@]}"
    echo "Estimated cleanup  : $(human_size "$RUNNER_DELETE_SIZE")"

    echo

    read -rp "Delete all candidate projects? [y/N] : " ANSWER

    case "$ANSWER" in

        y|Y|yes|YES|Yes)

            return 0

            ;;

        *)

            echo
            echo "Cleanup cancelled."

            return 1

            ;;

    esac

}


# ------------------------------------------------------------
# DELETE PROJECTS SAFELY
# ------------------------------------------------------------

delete_runner_projects() {

    local DELETED=0
    local SKIPPED=0
    local FREED_SIZE=0

    echo
    echo "Starting GitLab Runner cleanup..."
    echo


    for PROJECT in "${RUNNER_CANDIDATES[@]}"
    do

        # ----------------------------------------------------
        # SAFETY CHECK 1
        #
        # Project must still exist.
        # ----------------------------------------------------

        if [ ! -d "$PROJECT" ]; then

            echo "[SKIP] Project no longer exists:"
            echo "       $PROJECT"
            echo

            ((SKIPPED++))

            continue

        fi


        # ----------------------------------------------------
        # SAFETY CHECK 2
        #
        # Re-check newest activity immediately before delete.
        #
        # If timestamp changed since scan, something touched
        # the project after we classified it as candidate.
        #
        # This may indicate an active/new pipeline.
        # ----------------------------------------------------

        CURRENT_ACTIVITY=$(get_project_last_activity "$PROJECT")

        SCANNED_ACTIVITY="${RUNNER_SCAN_MTIME[$PROJECT]}"


        if [ "$CURRENT_ACTIVITY" != "$SCANNED_ACTIVITY" ]; then

            echo "[SKIP] New activity detected:"
            echo "       $PROJECT"
            echo

            ((SKIPPED++))

            continue

        fi


        # ----------------------------------------------------
        # SAFETY CHECK 3
        #
        # Re-check age.
        # ----------------------------------------------------

        NOW=$(date +%s)

        CURRENT_AGE=$(($((NOW - CURRENT_ACTIVITY)) / 86400))

        if [ "$CURRENT_AGE" -lt "$AGE_DAYS" ]; then

            echo "[SKIP] Project is no longer old enough:"
            echo "       $PROJECT"
            echo

            ((SKIPPED++))

            continue

        fi


        # ----------------------------------------------------
        # DELETE WHOLE PROJECT
        #
        # IMPORTANT:
        #
        # Never delete individual files.
        #
        # The entire project directory is removed atomically
        # as the cleanup unit.
        # ----------------------------------------------------

        PROJECT_SIZE="${RUNNER_PROJECT_SIZE[$PROJECT]}"

        echo "[DELETE] $PROJECT"
        echo "         Age  : ${RUNNER_PROJECT_AGE[$PROJECT]} days"
        echo "         Size : $(human_size "$PROJECT_SIZE")"


        if rm -rf -- "$PROJECT"; then

            echo "         Status: DELETED"

            ((DELETED++))

            ((FREED_SIZE += PROJECT_SIZE))

        else

            echo "         Status: FAILED"

            ((SKIPPED++))

        fi

        echo

    done


    # --------------------------------------------------------
    # SUMMARY
    # --------------------------------------------------------

    echo "========================================="
    echo "       GitLab Runner Cleanup Summary"
    echo "========================================="
    echo
    echo "Deleted Projects : $DELETED"
    echo "Skipped Projects : $SKIPPED"
    echo "Space Freed      : $(human_size "$FREED_SIZE")"
    echo
    echo "========================================="

}


# ------------------------------------------------------------
# MAIN RUNNER PROFILE
# ------------------------------------------------------------

runner_profile() {

    clear

    echo "========================================="
    echo "       GitLab Runner Cleanup"
    echo "========================================="

    #
    # STEP 1
    # Auto detect GitLab Runner build directories
    #
    if ! search_runner_directories; then

        echo
        read -rp "Press Enter to continue..."

        return

    fi


    #
    # STEP 2
    # Find actual projects inside Runner directories
    #
    scan_runner_projects


    if [ "${#RUNNER_PROJECTS[@]}" -eq 0 ]; then

        echo
        echo "No actual GitLab Runner projects found."

        echo
        echo "Runner directories checked:"

        for DIR in "${RUNNER_DIRECTORIES[@]}"
        do
            echo "  - $DIR"
        done

        echo
        read -rp "Press Enter to continue..."

        return

    fi


    #
    # STEP 3
    # Filter based on age + size
    #
    filter_runner_projects


    if [ "${#RUNNER_CANDIDATES[@]}" -eq 0 ]; then

        echo
        echo "Nothing to clean."

        echo
        read -rp "Press Enter to continue..."

        return

    fi


    #
    # STEP 4
    # Calculate estimated cleanup size
    #
    calculate_runner_size


    #
    # STEP 5
    # Confirmation
    #
    if ! confirm_runner_cleanup; then

        echo
        read -rp "Press Enter to continue..."

        return

    fi


    #
    # STEP 6
    # Delete
    #
    delete_runner_projects


    echo
    read -rp "Press Enter to continue..."
}