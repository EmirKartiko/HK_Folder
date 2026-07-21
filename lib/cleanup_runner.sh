scan_runner_projects() {

    RUNNER_PROJECTS=()

    echo
    echo "Scanning GitLab Runner..."
    echo

    for DIR in "${DIRECTORIES[@]}"
    do

        while IFS= read -r PROJECT
        do

            RUNNER_PROJECTS+=("$PROJECT")

        done < <(

            find "$DIR" \
                -mindepth 2 \
                -maxdepth 2 \
                -type d

        )

    done

    echo

    echo "Found ${#RUNNER_PROJECTS[@]} project(s)."

}

filter_runner_projects() {

    RUNNER_CANDIDATES=()

    local NOW
    NOW=$(date +%s)

    echo
    printf "%-60s %-10s\n" "Project" "Age(Days)"
    printf "%-60s %-10s\n" "------------------------------------------------------------" "----------"

    for PROJECT in "${RUNNER_PROJECTS[@]}"
    do

        MTIME=$(stat -c %Y "$PROJECT")

        PROJECT_AGE=$(( (NOW - MTIME) / 86400 ))

        printf "%-60s %-10s\n" "$PROJECT" "$PROJECT_AGE"

        if [ "$PROJECT_AGE" -ge "$AGE_DAYS" ]; then

            RUNNER_CANDIDATES+=("$PROJECT")

        fi

    done

    echo
    echo "Candidate Projects : ${#RUNNER_CANDIDATES[@]}"

}

calculate_runner_size() {

    RUNNER_DELETE_SIZE=0

    for PROJECT in "${RUNNER_CANDIDATES[@]}"
    do
        SIZE=$(du -sb "$PROJECT" 2>/dev/null | awk '{print $1}')

        ((RUNNER_DELETE_SIZE += SIZE))
    done

}

confirm_runner_cleanup() {

    echo
    read -rp "Delete all candidate projects? [y/N] : " ANSWER

    case "$ANSWER" in
        y|Y)
            return 0
            ;;
        *)
            return 1
            ;;
    esac

}

delete_runner_projects() {

    for PROJECT in "${RUNNER_CANDIDATES[@]}"
    do

        echo "Deleting $PROJECT"

        rm -rf "$PROJECT"

    done

}