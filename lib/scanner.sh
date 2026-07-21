DELETE_PATHS=()
DELETE_AGES=()
DELETE_SIZES=()
DELETE_REASONS=()

EXCLUDED_PATHS=()
EXCLUDED_AGES=()
EXCLUDED_SIZES=()
EXCLUDED_REASONS=()

scan_directories() {

    CANDIDATE_PATHS=()
    CANDIDATE_AGES=()
    CANDIDATE_SIZES=()
    CANDIDATE_REASONS=()

    TOTAL_SCANNED=0

    for DIR in "${DIRECTORIES[@]}"
    do
        scan_directory "$DIR"
    done

}

scan_directory() {

    local DIR="$1"

    echo
    echo "Scanning : $DIR"
    echo

    while IFS= read -r -d '' FILE
    do

        ((TOTAL_SCANNED++))
        
        evaluate_file "$FILE"

    done < <(

        find "$DIR" -type f -print0

    )

}

evaluate_file() {

    local FILE="$1"

    local FILE_SIZE
    local FILE_SIZE_MB
    local FILE_AGE

    local AGE_MATCH=0
    local SIZE_MATCH=0

    local REASON=""

    FILE_SIZE=$(stat -c%s "$FILE")
    FILE_SIZE_MB=$((FILE_SIZE/1024/1024))

    FILE_AGE=$(( ( $(date +%s) - $(stat -c %Y "$FILE") ) / 86400 ))

    ####################################
    # AGE
    ####################################

    if [ "$FILE_AGE" -ge "$AGE_DAYS" ]; then
        AGE_MATCH=1
        REASON="AGE"
    fi

    ####################################
    # SIZE
    ####################################

    if [ "$FILE_SIZE_MB" -ge "$SIZE_MB" ]; then
        SIZE_MATCH=1

        if [ -z "$REASON" ]; then
            REASON="SIZE"
        else
            REASON="$REASON+SIZE"
        fi
    fi

    ####################################
    # MODE
    ####################################

    MATCH=0

    if [ "$MODE" = "AND" ]; then

        if [ "$AGE_MATCH" -eq 1 ] && [ "$SIZE_MATCH" -eq 1 ]; then
            MATCH=1
        fi

    else

        if [ "$AGE_MATCH" -eq 1 ] || [ "$SIZE_MATCH" -eq 1 ]; then
            MATCH=1
        fi

    fi

    ####################################
    # SAVE CANDIDATE
    ####################################

    if [ "$MATCH" -eq 1 ]; then

        CANDIDATE_PATHS+=("$FILE")
        CANDIDATE_AGES+=("$FILE_AGE")
        CANDIDATE_SIZES+=("$FILE_SIZE")
        CANDIDATE_REASONS+=("$REASON")

    fi

}

preview_candidates() {

    clear

    echo "==============================================================="
    echo "                     Candidate Files"
    echo "==============================================================="
    printf "%-4s %-8s %-10s %-12s %s\n" \
        "No" "Age" "Size" "Reason" "File"

    echo "---------------------------------------------------------------"

    if [ ${#CANDIDATE_PATHS[@]} -eq 0 ]; then

        echo
        echo "No files matched."

        echo

        read -n1 -rsp "Press any key..."

        return

    fi

    TOTAL_SIZE=0

    for ((i=0;i<${#CANDIDATE_PATHS[@]};i++))
    do

        FILE="${CANDIDATE_PATHS[$i]}"

        AGE="${CANDIDATE_AGES[$i]}"

        SIZE="${CANDIDATE_SIZES[$i]}"

        REASON="${CANDIDATE_REASONS[$i]}"

        TOTAL_SIZE=$((TOTAL_SIZE+SIZE))

        if command -v numfmt >/dev/null
        then
            HUMAN_SIZE=$(numfmt --to=iec --suffix=B "$SIZE")
        else
            HUMAN_SIZE="${SIZE} Bytes"
        fi

        printf "%-4s %-8s %-10s %-12s %s\n" \
            "$((i+1))" \
            "${AGE}d" \
            "$HUMAN_SIZE" \
            "$REASON" \
            "$FILE"

    done

    echo "---------------------------------------------------------------"

    if command -v numfmt >/dev/null
    then
        TOTAL_SIZE=$(numfmt --to=iec --suffix=B "$TOTAL_SIZE")
    fi

    echo "Files Scanned   : $TOTAL_SCANNED"

    echo "Candidate Files : ${#CANDIDATE_PATHS[@]}"

    echo "Space To Free   : $TOTAL_SIZE"

    echo "---------------------------------------------------------------"

    echo

    #read -n1 -rsp "Press any key..."

}

prompt_exclude() {

    EXCLUDE_LIST=()

    echo
    echo "======================================================"
    echo "Exclude Files"
    echo "======================================================"
    echo
    echo "Examples:"
    echo "  2"
    echo "  2,5"
    echo "  1,3,8"
    echo
    echo "Press ENTER to continue without excluding."
    echo

    read -rp "Exclude: " INPUT

    [ -z "$INPUT" ] && return

    IFS=',' read -ra EXCLUDE_LIST <<< "$INPUT"

}

build_delete_list() {

    DELETE_PATHS=()
    DELETE_AGES=()
    DELETE_SIZES=()
    DELETE_REASONS=()

    EXCLUDED_PATHS=()
    EXCLUDED_AGES=()
    EXCLUDED_SIZES=()
    EXCLUDED_REASONS=()

    for ((i=0;i<${#CANDIDATE_PATHS[@]};i++))
    do

        NUMBER=$((i+1))

        EXCLUDED=0

        for IDX in "${EXCLUDE_LIST[@]}"
        do

            IDX=$(echo "$IDX" | xargs)

            if [ "$NUMBER" = "$IDX" ]; then
                EXCLUDED=1
                break
            fi

        done

        if [ "$EXCLUDED" -eq 1 ]; then

            EXCLUDED_PATHS+=("${CANDIDATE_PATHS[$i]}")
            EXCLUDED_AGES+=("${CANDIDATE_AGES[$i]}")
            EXCLUDED_SIZES+=("${CANDIDATE_SIZES[$i]}")
            EXCLUDED_REASONS+=("${CANDIDATE_REASONS[$i]}")

        else

            DELETE_PATHS+=("${CANDIDATE_PATHS[$i]}")
            DELETE_AGES+=("${CANDIDATE_AGES[$i]}")
            DELETE_SIZES+=("${CANDIDATE_SIZES[$i]}")
            DELETE_REASONS+=("${CANDIDATE_REASONS[$i]}")

        fi

    done

}

confirm_delete() {

    clear

    echo "=============================================================="
    echo "                 Files Ready To Delete"
    echo "=============================================================="

    if [ ${#DELETE_PATHS[@]} -eq 0 ]; then

        echo
        echo "Nothing to delete."
        echo

        read -n1 -rsp "Press any key..."
        return 1

    fi

    TOTAL_SIZE=0

    printf "%-4s %-8s %-10s %-12s %s\n" \
        "No" "Age" "Size" "Reason" "File"

    echo "--------------------------------------------------------------"

    for ((i=0;i<${#DELETE_PATHS[@]};i++))
    do

        SIZE="${DELETE_SIZES[$i]}"
        TOTAL_SIZE=$((TOTAL_SIZE+SIZE))

        if command -v numfmt >/dev/null
        then
            HUMAN_SIZE=$(numfmt --to=iec --suffix=B "$SIZE")
        else
            HUMAN_SIZE="${SIZE} Bytes"
        fi

        printf "%-4s %-8s %-10s %-12s %s\n" \
            "$((i+1))" \
            "${DELETE_AGES[$i]}d" \
            "$HUMAN_SIZE" \
            "${DELETE_REASONS[$i]}" \
            "${DELETE_PATHS[$i]}"

    done

    echo "--------------------------------------------------------------"

    if command -v numfmt >/dev/null
    then
        TOTAL_SIZE=$(numfmt --to=iec --suffix=B "$TOTAL_SIZE")
    fi

    echo
    echo "Files To Delete : ${#DELETE_PATHS[@]}"
    echo "Excluded Files  : ${#EXCLUDED_PATHS[@]}"
    echo "Space To Free   : $TOTAL_SIZE"

    echo

        if [ ${#EXCLUDED_PATHS[@]} -gt 0 ]; then

        echo
        echo "Excluded Files:"
        echo

        for FILE in "${EXCLUDED_PATHS[@]}"
        do
            echo " - $FILE"
        done

    fi

    echo
    read -rp "Proceed with deletion? [Y/n]: " ANSWER

    ANSWER=${ANSWER:-Y}

    case "$ANSWER" in
        Y|y|YES|yes)
            return 0
            ;;
        *)
            echo
            echo "Operation cancelled."
            read -n1 -rsp "Press any key..."
            return 1
            ;;
    esac

}

confirm_delete_quick() {

    clear

    echo "=============================================================="
    echo "                Quick Cleanup Summary"
    echo "=============================================================="
    echo

    if [ ${#DELETE_PATHS[@]} -eq 0 ]; then

        echo "No files to delete."
        echo

        read -n1 -rsp "Press any key..."
        return 1

    fi

    TOTAL_SIZE=0

    for SIZE in "${DELETE_SIZES[@]}"
    do
        TOTAL_SIZE=$((TOTAL_SIZE + SIZE))
    done

    if command -v numfmt >/dev/null
    then
        HUMAN_SIZE=$(numfmt --to=iec --suffix=B "$TOTAL_SIZE")
    else
        HUMAN_SIZE="${TOTAL_SIZE} Bytes"
    fi

    printf "%-22s : %s\n" "Directories Scanned" "${#DIRECTORIES[@]}"
    printf "%-22s : %s\n" "Files Scanned" "$TOTAL_SCANNED"
    printf "%-22s : %s\n" "Files To Delete" "${#DELETE_PATHS[@]}"
    printf "%-22s : %s\n" "Space To Free" "$HUMAN_SIZE"

    echo

    ####################################################
    # Warning
    ####################################################

    if [ ${#DELETE_PATHS[@]} -ge 10000 ] || \
       [ "$TOTAL_SIZE" -ge $((100 * 1024 * 1024 * 1024)) ]; then

        echo "############################################################"
        echo "# WARNING : LARGE CLEANUP OPERATION"
        echo "#"
        echo "# ${#DELETE_PATHS[@]} files will be permanently deleted."
        echo "#"
        echo "# Deleted files cannot be recovered."
        echo "# SOMETHING HAPPEN YOU WILL BE FUCK"
        echo "# You have been warned."
        echo "############################################################"
        echo

    elif [ ${#DELETE_PATHS[@]} -ge 1000 ]; then

        echo "------------------------------------------------------------"
        echo "Warning : More than 1,000 files will be deleted."
        echo "Please ensure this cleanup is intended."
        echo "You have been warned."
        echo "------------------------------------------------------------"
        echo

    fi

    read -rp "Fuck it ? [Y/n]: " ANSWER

    ANSWER=${ANSWER:-Y}

    case "$ANSWER" in
        Y|y|YES|yes)
            return 0
            ;;
        *)
            echo
            echo "Lemah...."
            echo "You're Wimp"
            echo "Pathetic..."
            echo "Operation cancelled."
            read -n1 -rsp "Press any key..."
            return 1
            ;;
    esac

}