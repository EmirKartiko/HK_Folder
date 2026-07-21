DRY_RUN=false

capture_disk_before() {

    DISK_BEFORE=()

    for DIR in "${DIRECTORIES[@]}"
    do

        FILESYSTEM=$(df -P "$DIR" | awk 'NR==2 {print $1}')

        # Skip jika filesystem sudah pernah dicatat
        FOUND=0

        for ITEM in "${DISK_BEFORE[@]}"
        do
            FS=$(echo "$ITEM" | cut -d'|' -f1)

            if [ "$FS" = "$FILESYSTEM" ]; then
                FOUND=1
                break
            fi
        done

        [ "$FOUND" -eq 1 ] && continue

        USED=$(df -P "$DIR" | awk 'NR==2 {print $5}')

        DISK_BEFORE+=("$FILESYSTEM|$USED")

    done

}

delete_files() {

    DELETED_FILES=0
    FAILED_FILES=0
    SPACE_RECLAIMED=0

    START_TIME=$(date +%s)

    TOTAL=${#DELETE_PATHS[@]}

    echo
    echo "Deleting files..."
    echo

    for ((i=0;i<TOTAL;i++))
    do

        FILE="${DELETE_PATHS[$i]}"
        SIZE="${DELETE_SIZES[$i]}"

        CURRENT=$((i+1))

        printf "\r[%d/%d] %s" \
            "$CURRENT" \
            "$TOTAL" \
            "$FILE"

        #########################################
        # File masih ada?
        #########################################

        if [ ! -f "$FILE" ]; then
            ((FAILED_FILES++))
            continue
        fi

        #########################################
        # DRY RUN
        #########################################

        if [ "$DRY_RUN" = true ]; then

            ((DELETED_FILES++))
            SPACE_RECLAIMED=$((SPACE_RECLAIMED+SIZE))

            continue

        fi

        #########################################
        # DELETE
        #########################################

        if rm -f -- "$FILE"
        then

            ((DELETED_FILES++))
            SPACE_RECLAIMED=$((SPACE_RECLAIMED+SIZE))

        else

            ((FAILED_FILES++))

        fi

    done

    echo

    END_TIME=$(date +%s)

    DURATION=$((END_TIME-START_TIME))

}

remove_empty_directories() {

    REMOVED_DIRECTORIES=0

    echo
    echo "Removing empty directories..."
    echo

    for DIR in "${DIRECTORIES[@]}"
    do

        while IFS= read -r -d '' EMPTY
        do

            if rmdir "$EMPTY"
            then

                ((REMOVED_DIRECTORIES++))

                echo "Removed : $EMPTY"

            fi

        done < <(

            find "$DIR" \
                -depth \
                -type d \
                -empty \
                -print0

        )

    done

}

capture_disk_after() {

    DISK_AFTER=()

    for DIR in "${DIRECTORIES[@]}"
    do

        FILESYSTEM=$(df -P "$DIR" | awk 'NR==2 {print $1}')

        FOUND=0

        for ITEM in "${DISK_AFTER[@]}"
        do

            FS=$(echo "$ITEM" | cut -d'|' -f1)

            if [ "$FS" = "$FILESYSTEM" ]; then
                FOUND=1
                break
            fi

        done

        [ "$FOUND" -eq 1 ] && continue

        USED=$(df -P "$DIR" | awk 'NR==2 {print $5}')

        DISK_AFTER+=("$FILESYSTEM|$USED")

    done

}

quick_cleanup() {

    scan_directories

    build_delete_list

    capture_disk_before

    confirm_delete_quick || return

    delete_files

    capture_disk_after

    show_summary

}

advanced_cleanup() {

    scan_directories

    build_delete_list

    preview_candidates

    prompt_exclude

    capture_disk_before

    confirm_delete || return

    delete_files

    capture_disk_after

    show_summary

}


confirm_delete_quick() {

    clear

    echo "========================================="
    echo "        Quick Cleanup"
    echo "========================================="
    echo

    echo "Ready to delete old files."

    echo

    read -rp "Continue? [Y/n] : " ANSWER

    case "$ANSWER" in

        ""|Y|y)

            return 0

            ;;

        *)

            echo

            echo "Cleanup cancelled."

            sleep 1

            return 1

            ;;

    esac

}

