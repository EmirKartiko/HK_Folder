docker_profile() {

    if ! command -v docker >/dev/null 2>&1
    then
        echo
        echo "Docker is not installed."
        read -n1 -rsp "Press any key..."
        return 1
    fi

    if ! docker info >/dev/null 2>&1
    then
        echo
        echo "Docker daemon is not running."
        read -n1 -rsp "Press any key..."
        return 1
    fi

    return 0

}

docker_menu() {

    while true
    do

        clear

        echo "========================================="
        echo "        Docker Housekeeping"
        echo "========================================="
        echo
        echo "1. Quick Cleanup"
        echo "2. Advanced Cleanup"
        echo "3. Show Docker Usage"
        echo "4. Back"
        echo

        echo "========================================="
        echo "note:"
        echo "1. Quick Cleanup: Cleans up stopped containers, dangling images, build cache, and unused networks."
        echo "2. Advanced Cleanup: Provides options to clean up specific Docker resources, and remove not only dangling but also unused."
        echo "3. Show Docker Usage: Displays the current disk usage of Docker resources."
        echo "========================================="

        read -rp "Select Menu : " CHOICE

        case "$CHOICE" in

            1)

                docker_profile || continue
                docker_quick_cleanup
                ;;

            2)

                docker_profile || continue
                docker_advanced_menu
                ;;

            3)

                docker_profile || continue
                docker_usage
                ;;

            4)

                return
                ;;

            *)

                echo
                echo "Invalid choice."
                sleep 1
                ;;

        esac

    done

}

docker_usage() {

    clear

    echo "========================================="
    echo "         Docker Disk Usage"
    echo "========================================="
    echo

    docker system df

    echo
    read -n1 -rsp "Press any key..."

}

docker_quick_cleanup() {

    clear

    echo "========================================="
    echo "        Docker Quick Cleanup"
    echo "========================================="
    echo

    echo "Docker usage before cleanup"
    echo

    docker system df

    echo

    read -rp "Proceed? [Y/n]: " ANSWER

    ANSWER=${ANSWER:-Y}

    case "$ANSWER" in

        Y|y|YES|yes)
            ;;

        *)
            return
            ;;

    esac

    echo
    echo "Cleaning stopped containers..."
    docker container prune -f

    echo
    echo "Cleaning dangling images..."
    docker image prune -f

    echo
    echo "Cleaning build cache..."
    docker builder prune -f

    echo
    echo "Cleaning unused networks..."
    docker network prune -f

    echo
    echo "========================================="
    echo "      Docker usage after cleanup"
    echo "========================================="
    echo
    docker system df

    echo
    read -n1 -rsp "Press any key..."

}

docker_advanced_menu() {

    while true
    do

        clear

        echo "========================================="
        echo "      Docker Advanced Cleanup"
        echo "========================================="
        echo
        echo "1. Containers"
        echo "2. Images"
        echo "3. Builder Cache"
        echo "4. Networks"
        echo "5. Volumes"
        echo "6. Full Cleanup"
        echo "7. Back"
        echo

        read -rp "Select Menu : " CHOICE

        case "$CHOICE" in

            1)

                docker_container_cleanup
                ;;

            2)

                docker_image_cleanup
                ;;

            3)

                docker_builder_cleanup
                ;;

            4)

                docker_network_cleanup
                ;;

            5)

                docker_volume_cleanup
                ;;

            6)

                docker_full_cleanup
                ;;

            7)

                return
                ;;

            *)

                echo
                echo "Invalid choice."
                sleep 1
                ;;

        esac

    done

}

docker_container_cleanup() {

    clear

    echo "========================================="
    echo "        Docker Container Cleanup"
    echo "========================================="
    echo

    echo "Docker container before cleanup"
    echo

    docker ps --filter "status=exited"

    echo

    read -rp "Proceed? [Y/n]: " ANSWER

    ANSWER=${ANSWER:-Y}

    case "$ANSWER" in

        Y|y|YES|yes)
            ;;

        *)
            return
            ;;

    esac

    echo
    echo "Cleaning stopped containers..."
    docker container prune -f

    echo
    echo "========================================="
    echo "      Docker container after cleanup"
    echo "========================================="
    echo
    docker ps --filter "status=exited"

    echo
    read -n1 -rsp "Press any key..."

}


docker_image_cleanup() {

    clear

    echo "========================================="
    echo "        Docker Image Cleanup"
    echo "========================================="
    echo

    echo "Docker images before cleanup"
    echo

    docker image ls

    echo

    read -rp "Proceed? [Y/n]: " ANSWER

    ANSWER=${ANSWER:-Y}

    case "$ANSWER" in

        Y|y|YES|yes)
            ;;

        *)
            return
            ;;

    esac

    echo
    echo "Cleaning stopped containers..."
    docker image prune -a -f

    echo
    echo "========================================="
    echo "      Docker images after cleanup"
    echo "========================================="
    echo
    docker image ls

    echo
    read -n1 -rsp "Press any key..."

}

docker_builder_cleanup() {

    clear

    echo "========================================="
    echo "        Docker Builder Cleanup"
    echo "========================================="
    echo

    echo "Docker builder before cleanup"
    echo

    docker builder ls

    echo

    read -rp "Proceed? [Y/n]: " ANSWER

    ANSWER=${ANSWER:-Y}

    case "$ANSWER" in

        Y|y|YES|yes)
            ;;

        *)
            return
            ;;

    esac

    echo
    echo "Cleaning Old Builder Cache (2 Weeks Old or more)..."
    docker builder prune --filter "until=336h" -f

    echo
    echo "========================================="
    echo "      Docker builder after cleanup"
    echo "========================================="
    echo
    docker builder ls

    echo
    read -n1 -rsp "Press any key..."

}

docker_network_cleanup() {
    clear

    echo "========================================="
    echo "        Docker Network Cleanup"
    echo "========================================="
    echo

    echo "Docker network before cleanup"
    echo

    docker network ls

    echo

    read -rp "Proceed? [Y/n]: " ANSWER

    ANSWER=${ANSWER:-Y}

    case "$ANSWER" in

        Y|y|YES|yes)
            ;;

        *)
            return
            ;;

    esac

    echo
    echo "Cleaning Unused Networks..."
    docker network prune -f

    echo
    echo "========================================="
    echo "      Docker network after cleanup"
    echo "========================================="
    echo
    docker network ls

    echo
    read -n1 -rsp "Press any key..."

}

docker_volume_cleanup() {

    clear

    echo "========================================="
    echo "        Docker Volume Cleanup"
    echo "========================================="
    echo

    echo "Docker volume before cleanup"
    echo

    docker volume ls

    echo

    read -rp "Proceed? [Y/n]: " ANSWER

    ANSWER=${ANSWER:-Y}

    case "$ANSWER" in

        Y|y|YES|yes)
            ;;

        *)
            return
            ;;

    esac

    echo
    echo "Cleaning Unused Volumes..."
    docker volume prune -af

    echo
    echo "========================================="
    echo "      Docker volume after cleanup"
    echo "========================================="
    echo
    docker volume ls

    echo
    read -n1 -rsp "Press any key..."

}

docker_full_cleanup() {

    clear

    echo "========================================="
    echo "        Docker Usage Cleanup"
    echo "========================================="
    echo

    echo "Docker Usage before cleanup"
    echo

    docker system df

    echo

    read -rp "Proceed? [Y/n]: " ANSWER

    ANSWER=${ANSWER:-Y}

    case "$ANSWER" in

        Y|y|YES|yes)
            ;;

        *)
            return
            ;;

    esac

    echo
    echo "Cleaning Docker..."
    docker system prune -af

    echo
    echo "========================================="
    echo "      Docker usage after cleanup"
    echo "========================================="
    echo
    docker system df

    echo
    read -n1 -rsp "Press any key..."

}