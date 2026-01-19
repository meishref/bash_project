#!/usr/bin/env bash

# Colors
Red="\033[31m"
Green="\033[32m"
Reset="\033[0m"

# DBMS Root Directory
DBMS_DIR="$HOME/.DBMS"

##################################
# Create Database
##################################
create_db() {

    mkdir -p "$DBMS_DIR"

    valid_db=0
    while [[ $valid_db -eq 0 ]]; do
        read -p "Enter Database Name: " db
        db=$(tr " " "_" <<< "$db")

        if [[ -z "$db" ]]; then
            echo "Database name cannot be empty"
        elif [[ "$db" = [0-9]* ]]; then
            echo "Database name cannot start with number"
        elif [[ "$db" == "_" ]]; then
            echo "Invalid database name"
        elif [[ ! "$db" =~ ^[a-zA-Z][a-zA-Z0-9_]*$ ]]; then
            echo "Invalid characters in database name"
        elif [[ -d "$DBMS_DIR/$db" ]]; then
            echo "Database already exists"
        else
            valid_db=1
        fi
    done

    mkdir "$DBMS_DIR/$db"
    echo -e "${Green}Database '$db' created successfully${Reset}"
}

##################################
# List Databases
##################################
list_db() {

    mkdir -p "$DBMS_DIR"

    databases=$(ls -F "$DBMS_DIR" | grep '/' | tr -d '/')

    if [[ -z "$databases" ]]; then
        echo "No databases found"
    else
        echo "Available Databases:"
        echo "$databases"
    fi
}

##################################
# Connect Database
##################################
connect_db() {

    read -p "Enter Database Name: " db
    db=$(tr " " "_" <<< "$db")

    if [[ -z "$db" ]]; then
        echo "Database name cannot be empty"
    elif [[ ! -d "$DBMS_DIR/$db" ]]; then
        echo -e "${Red}Database not found${Reset}"
    else
        cd "$DBMS_DIR/$db"

        export PS3="$db>> "
        source "$(dirname "$0")/table.sh"
        export PS3="DBMS>> "
    fi
}

##################################
# Remove Database
##################################
remove_db() {

    databases=$(ls "$DBMS_DIR" 2>/dev/null)

    if [[ -z "$databases" ]]; then
        echo "No databases to remove"
    else
        export PS3="RemoveDB>> "

        select db in $databases "Cancel"
        do
            if [[ "$db" == "Cancel" ]]; then
                break
            elif [[ -d "$DBMS_DIR/$db" ]]; then
                read -p "Type YES to confirm delete database '$db': " confirm
                if [[ "$confirm" == "YES" ]]; then
                    rm -r "$DBMS_DIR/$db"
                    echo -e "${Green}Database '$db' removed${Reset}"
                else
                    echo "Delete cancelled"
                fi
                break
            else
                echo "Invalid selection"
            fi
        done
    fi
}
