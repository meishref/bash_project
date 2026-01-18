#!/usr/bin/env bash

# Get project root directory (works anywhere)
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source functions safely
source "$PROJECT_DIR/db_functions.sh"

menu=("CreateDB" "ListDB" "ConnectDB" "RemoveDB" "Exit")
export PS3="DBMS>> "

select choice in "${menu[@]}"
do
    case $REPLY in
        1) create_db ;;
        2) list_db ;;
        3) connect_db ;;
        4) remove_db ;;
        5) break ;;
        *) echo "Invalid Choice" ;;
    esac
done
