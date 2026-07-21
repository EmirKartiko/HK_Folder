main_menu() {

    while true
    do

        clear

        echo "========================================="
        echo "             WELCOME TO"
        echo "       HK FOLDER MANAGER v0.1"
        echo "========================================="
        echo

        echo "1. Run Cleanup"
        echo "2. Configuration"
        echo "3. View Configuration"
        echo "4. Dry Run"
        echo "5. Exit"

        echo "========================================="
        echo "            By Emeng Irul"
        echo "========================================="
        echo

        read -rp "Choice: " CHOICE

        case "$CHOICE" in

            1)
                cleanup_menu
                ;;

            2)
                configuration_menu
                ;;

            3)
                view_configuration
                ;;

            4)
                echo "Coming in Stage 2"
                read -n1 -rsp "Press any key..."
                ;;

            5)
                exit 0
                ;;

            *)
                echo "Invalid choice."
                sleep 1
                ;;

        esac

    done

}

configuration_menu() {

    while true
    do

        clear

        echo "========================================="
        echo " Configuration"
        echo "========================================="

        echo

        echo "1. Change Age"
        echo "2. Change Size"
        echo "3. Change Mode"
        echo "4. Manage Directories"
        echo "5. Back"

        echo

        read -rp "Choice: " CHOICE

        case "$CHOICE" in

            1)
                get_age
                save_config
                ;;

            2)
                get_size
                save_config
                ;;

            3)
                get_mode
                save_config
                ;;

            4)
                manage_directories
                ;;

            5)
                break
                ;;

        esac

    done

}

manage_directories() {

    while true
    do

        clear

        echo "========================================="
        echo "      Manage Directories"
        echo "========================================="
        echo

        if [ ${#DIRECTORIES[@]} -eq 0 ]; then
            echo "No directories configured."
        else

            COUNT=1

            for DIR in "${DIRECTORIES[@]}"
            do
                echo "$COUNT. $DIR"
                ((COUNT++))
            done

        fi

        echo
        echo "-----------------------------------------"
        echo "1. Add Directory"
        echo "2. Remove Directory"
        echo "3. Back"
        echo "-----------------------------------------"

        echo

        read -rp "Choice: " CHOICE

        case "$CHOICE" in

            1)
                add_directory
                ;;

            2)
                remove_directory
                ;;

            3)
                break
                ;;

            *)
                echo "Invalid choice."
                sleep 1
                ;;

        esac

    done

}

add_directory() {

    echo

    read -rp "Directory: " DIR

    [ -z "$DIR" ] && return

    if [ ! -d "$DIR" ]; then
        echo "Directory does not exist."
        read -n1 -rsp "Press any key..."
        return
    fi

    if [ ! -r "$DIR" ]; then
        echo "Directory is not readable."
        read -n1 -rsp "Press any key..."
        return
    fi

    for EXISTING in "${DIRECTORIES[@]}"
    do
        if [ "$DIR" = "$EXISTING" ]; then
            echo "Directory already exists."
            read -n1 -rsp "Press any key..."
            return
        fi
    done

    DIRECTORIES+=("$DIR")

    save_directories

    echo
    echo "Directory added successfully."

    read -n1 -rsp "Press any key..."

}

remove_directory() {

    if [ ${#DIRECTORIES[@]} -eq 0 ]; then

        echo

        echo "No directory to remove."

        read -n1 -rsp "Press any key..."

        return

    fi

    echo

    read -rp "Remove directory number: " NUMBER

    if ! [[ "$NUMBER" =~ ^[0-9]+$ ]]; then
        echo "Invalid input."
        read -n1 -rsp "Press any key..."
        return
    fi

    INDEX=$((NUMBER-1))

    if [ "$INDEX" -lt 0 ] || [ "$INDEX" -ge "${#DIRECTORIES[@]}" ]; then
        echo "Directory number not found."
        read -n1 -rsp "Press any key..."
        return
    fi

    unset DIRECTORIES[$INDEX]

    DIRECTORIES=("${DIRECTORIES[@]}")

    save_directories

    echo
    echo "Directory removed."

    read -n1 -rsp "Press any key..."

}

capture_disk_before() {

    DISK_BEFORE=()

    for DIR in "${DIRECTORIES[@]}"
    do

        FILESYSTEM=$(df -P "$DIR" | awk 'NR==2 {print $1}')
        MOUNT=$(df -P "$DIR" | awk 'NR==2 {print $6}')
        USED=$(df -P "$DIR" | awk 'NR==2 {print $5}')

        FOUND=0

        for ITEM in "${DISK_BEFORE[@]}"
        do

            FS=$(echo "$ITEM" | cut -d'|' -f1)

            if [ "$FS" = "$FILESYSTEM" ]
            then
                FOUND=1
                break
            fi

        done

        [ "$FOUND" -eq 1 ] && continue

        DISK_BEFORE+=("$FILESYSTEM|$MOUNT|$USED")

    done

}

capture_disk_after() {

    DISK_AFTER=()

    for DIR in "${DIRECTORIES[@]}"
    do

        FILESYSTEM=$(df -P "$DIR" | awk 'NR==2 {print $1}')
        MOUNT=$(df -P "$DIR" | awk 'NR==2 {print $6}')
        USED=$(df -P "$DIR" | awk 'NR==2 {print $5}')

        FOUND=0

        for ITEM in "${DISK_AFTER[@]}"
        do

            FS=$(echo "$ITEM" | cut -d'|' -f1)

            if [ "$FS" = "$FILESYSTEM" ]
            then
                FOUND=1
                break
            fi

        done

        [ "$FOUND" -eq 1 ] && continue

        DISK_AFTER+=("$FILESYSTEM|$MOUNT|$USED")

    done

}

show_summary() {

    clear

    echo "============================================================"
    echo "                   Cleanup Summary"
    echo "============================================================"
    echo

    printf "%-25s : %s\n" "Directories Scanned" "${#DIRECTORIES[@]}"
    printf "%-25s : %s\n" "Files Scanned" "$TOTAL_SCANNED"
    printf "%-25s : %s\n" "Matched Files" "${#CANDIDATE_PATHS[@]}"
    printf "%-25s : %s\n" "Excluded Files" "${#EXCLUDED_PATHS[@]}"
    printf "%-25s : %s\n" "Deleted Files" "$DELETED_FILES"
    printf "%-25s : %s\n" "Failed Delete" "$FAILED_FILES"
    printf "%-25s : %s\n" "Directories Removed" "$REMOVED_DIRECTORIES"

    if command -v numfmt >/dev/null
    then
        SPACE=$(numfmt --to=iec --suffix=B "$SPACE_RECLAIMED")
    else
        SPACE="${SPACE_RECLAIMED} Bytes"
    fi

    printf "%-25s : %s\n" "Space Reclaimed" "$SPACE"
    printf "%-25s : %s Seconds\n" "Duration" "$DURATION"

    echo
    echo "------------------------------------------------------------"
    printf "%-18s %-12s %-10s %-10s\n" \
        "Filesystem" \
        "Mount" \
        "Before" \
        "After"

    echo "------------------------------------------------------------"

    for ((i=0;i<${#DISK_BEFORE[@]};i++))
    do

        BEFORE="${DISK_BEFORE[$i]}"
        AFTER="${DISK_AFTER[$i]}"

        FS=$(echo "$BEFORE" | cut -d'|' -f1)
        MOUNT=$(echo "$BEFORE" | cut -d'|' -f2)
        BEFORE_USE=$(echo "$BEFORE" | cut -d'|' -f3)
        AFTER_USE=$(echo "$AFTER" | cut -d'|' -f3)

        printf "%-18s %-12s %-10s %-10s\n" \
            "$FS" \
            "$MOUNT" \
            "$BEFORE_USE" \
            "$AFTER_USE"

    done

    echo
    echo "============================================================"

    read -n1 -rsp "Press any key..."

}

cleanup_menu() {

    while true
    do

        clear

        echo "========================================="
        echo "             Cleanup Menu"
        echo "========================================="
        echo

        echo "1. GitLab Runner"
        echo "2. System Logs"
        echo "3. Journal"
        echo "4. Docker"
        echo "5. Custom Directory"
        echo "6. Configured Directories"
        echo "7. Back"

        echo
        echo "========================================="
        echo "note:"
        echo "1.GitLab Runner: Cleans up GitLab Runner projects based on the configured age and size."
        echo "2.System Logs: Cleans up system log files based on the configured age and size."
        echo "3.Journal: Cleans up system journal logs based on the configured age and size."
        echo "4.Docker: Provides options to clean up Docker resources, including containers, images, and networks."
        echo "5.Custom Directory: Cleans up files in a user-specified directory based on the configured age and size."
        echo "6.Configured Directories: Cleans up files in directories specified in the configuration file based on the configured age and size."
        echo "========================================="
        echo

        read -rp "Choice: " CHOICE

        case "$CHOICE" in

            1)

                if runner_profile
                then

                    scan_runner_projects

                    filter_runner_projects

                    calculate_runner_size

                    confirm_runner_cleanup || break

                    delete_runner_projects

                    read -n1 -rsp "Press any key..."

                fi
                ;;

            2)

                if logs_profile
                then

                    quick_cleanup

                fi
                ;;

            3)

                if journal_profile
                then

                    quick_cleanup

                fi

                ;;

            4)
                docker_menu
                ;;

            5)

                if custom_profile
                then

                    custom_cleanup_menu
                    

                fi

                ;;
            6)

                if configured_profile
                then

                    configured_cleanup_menu

                fi

                ;;
            7)

                break

                ;;

            *)

                echo "Invalid choice."

                sleep 1

                ;;

        esac

    done

}

quick_cleanup() {

    scan_directories

    if [ ${#CANDIDATE_PATHS[@]} -eq 0 ]; then

        echo
        echo "No files matched."
        read -n1 -rsp "Press any key..."
        return

    fi

    EXCLUDE_LIST=()

    build_delete_list

    capture_disk_before

    if confirm_delete_quick
    then

        delete_files

        capture_disk_after

        show_summary

    fi

}

advanced_cleanup() {

    scan_directories

    if [ ${#CANDIDATE_PATHS[@]} -eq 0 ]; then

        echo
        echo "No files matched."
        read -n1 -rsp "Press any key..."
        return

    fi

    preview_candidates

    prompt_exclude

    build_delete_list

    capture_disk_before

    if confirm_delete
    then

        delete_files

        capture_disk_after

        show_summary

    fi

}

runner_cleanup_menu() {

    while true
    do

        clear

        echo "========================================="
        echo "       GitLab Runner Cleanup"
        echo "========================================="
        echo

        echo "1. Quick Cleanup"
        echo "2. Advanced Cleanup"
        echo "3. Back"

        echo

        echo "========================================="
        echo "note:"
        echo "1. Quick Cleanup: Cleans up server based on the configured directories, age and size"
        echo "2. Advanced Cleanup: Provides options to clean up specific files and directories."
        echo "========================================="
        echo

        read -rp "Choice: " CHOICE

        case "$CHOICE" in

            1)

                QUICK_MODE=true

                quick_cleanup

                break

                ;;

            2)

                QUICK_MODE=false

                advanced_cleanup

                break

                ;;

            3)

                break

                ;;

        esac

    done

}

custom_cleanup_menu() {

    while true
    do

        clear

        echo "========================================="
        echo "        Custom Directory"
        echo "========================================="
        echo

        echo "1. Quick Cleanup"
        echo "2. Advanced Cleanup"
        echo "3. Back"

        echo
        echo "========================================="
        echo "note:"
        echo "1. Quick Cleanup: Cleans up server based on the configured directories, age and size."
        echo "2. Advanced Cleanup: Provides options to clean up specific files and directories."
        echo "========================================="
        echo
        read -rp "Choice: " CHOICE

        case "$CHOICE" in

            1)

                QUICK_MODE=true

                quick_cleanup

                break

                ;;

            2)

                QUICK_MODE=false

                advanced_cleanup

                break

                ;;

            3)

                break

                ;;

        esac

    done

}

configured_cleanup_menu() {

    while true
    do

        clear

        echo "========================================="
        echo "    Configured Directory Cleanup"
        echo "========================================="
        echo
        echo "1. Quick Cleanup"
        echo "2. Advanced Cleanup"
        echo "3. Back"
        echo

        read -rp "Choice: " CHOICE

        case "$CHOICE" in

            1)

                quick_cleanup

                break
                ;;

            2)

                advanced_cleanup

                break
                ;;

            3)

                break
                ;;

            *)

                echo "Invalid choice."
                sleep 1
                ;;

        esac

    done

}