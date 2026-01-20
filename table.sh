#!/usr/bin/env bash


PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"


source "$PROJECT_DIR/table_functions.sh"

menu=(
    "Create Table"
    "List Tables"
    "Insert Row"
    "Select Data"
    "Update Row"
    "Delete Row"
    "Drop Table"
    "Back"
)

export PS3="Table>> "

select choice in "${menu[@]}"
do
    case $REPLY in
        1)
            create_table
        ;;
        2)
            echo "Available Tables:"
            ls *.meta 2>/dev/null | sed 's/.meta//'
        ;;
        3)
            insert_row
        ;;
        4)
            select_table
        ;;
        5)
            update_row
        ;;
        6)
            delete_row
        ;;
        7)
            drop_table
        ;;
        8)
            echo "Returning to DB Menu..."
        ;;
        *)
            echo "Invalid Choice, select number 1-8"
        ;;
    esac
done
