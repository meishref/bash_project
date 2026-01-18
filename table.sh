#!/usr/bin/env bash

# Get project root directory safely
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source table functions
source "$PROJECT_DIR/table_functions.sh"

menu=("CreateTable" "ListTables" "Insert" "Select" "Delete" "Update" "Back")
export PS3="Table>> "

select ch in "${menu[@]}"
do
    case $REPLY in
        1) create_table ;;
        2) ls *.data 2>/dev/null | sed 's/.data//' ;;
        3) insert_row ;;
        4) select_table ;;
        5) delete_row ;;
        6) update_row ;;
        7) break ;;
        *) echo "Invalid Choice" ;;
    esac
done
