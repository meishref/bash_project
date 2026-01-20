#!/usr/bin/env bash


PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"


source "$PROJECT_DIR/db_functions.sh"

export PS3="DBMS>> "

menu=(
    "Create Database"
    "List Databases"
    "Connect Database"
    "Remove Database"
    "Exit"
)

while true
do
    select choice in "${menu[@]}"
    do
        case $REPLY in
            1)
                create_db
                break
            ;;
            2)
                list_db
                break
            ;;
            3)
                connect_db
                break
            ;;
            4)
                remove_db
                break
            ;;
            5)
                echo "Exiting DBMS..."
                exit
            ;;
            *)
                echo "Invalid choice, select 1-5"
                break
            ;;
        esac
    done
done
