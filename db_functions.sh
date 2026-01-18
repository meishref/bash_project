#!/usr/bin/env bash

# Get project root directory (portable)
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source utils safely
source "$PROJECT_DIR/utils.sh"

##################################
# Create Database
##################################
create_db() {
    mkdir -p "$DBMS_DIR"

    read -p "DB Name: " db
    db=${db// /_}

    validate_name "$db" "Database" || return

    if [[ -d $DBMS_DIR/$db ]]; then
        echo -e "$Red DB Exists $Reset"
    else
        mkdir "$DBMS_DIR/$db"
        echo -e "$Green DB Created $Reset"
    fi
}

##################################
# List Databases
##################################
list_db() {
    mkdir -p "$DBMS_DIR"

    data=$(ls -F "$DBMS_DIR" | grep '/' | tr -d '/')
    [[ -z $data ]] && echo "No Databases Found" || echo "$data"
}

##################################
# Connect Database
##################################
connect_db() {
    read -p "DB Name: " db
    db=${db// /_}

    validate_name "$db" "Database" || return

    if [[ -d $DBMS_DIR/$db ]]; then
        cd "$DBMS_DIR/$db" || return

        export PS3="$db>> "
        source "$PROJECT_DIR/table.sh"
        export PS3="DBMS>> "
    else
        echo -e "$Red DB Not Found $Reset"
    fi
}

##################################
# Remove Database
##################################
remove_db() {
    export PS3="RemoveDB>> "

    select db in $(ls "$DBMS_DIR")
    do
        if [[ -n $db && -d $DBMS_DIR/$db ]]; then
            rm -r "$DBMS_DIR/$db"
            echo -e "$Green DB Removed $Reset"
        else
            echo -e "$Red Invalid Selection $Reset"
        fi

        export PS3="DBMS>> "
        break
    done
}
