#!/usr/bin/env bash
shopt -s extglob

# ===== Colors =====
readonly Red="\e[31m"
readonly Green="\e[32m"
readonly Yellow="\e[33m"
readonly Reset="\e[0m"

# ===== DBMS Root =====
readonly DBMS_DIR="$HOME/.DBMS"

#################################
# Validate Names (DB / Table / Column)
#################################
validate_name() {
    local name="$1"
    local type="$2"

    # Empty
    if [[ -z $name ]]; then
        echo -e "$Red Error: $type name can't be empty $Reset"
        return 1
    fi

    # Starts with number
    if [[ $name == [0-9]* ]]; then
        echo -e "$Red Error: $type name can't start with number $Reset"
        return 1
    fi

    # Only underscore
    if [[ $name == "_" ]]; then
        echo -e "$Red Error: $type name can't be '_' $Reset"
        return 1
    fi

    # Invalid characters
    if [[ ! $name =~ ^[a-zA-Z][a-zA-Z0-9_]*$ ]]; then
        echo -e "$Red Error: Invalid $type name $Reset"
        return 1
    fi

    return 0
}

#################################
# Validate Datatype
#################################
validate_datatype() {
    case "$1" in
        int|string)
            return 0
        ;;
        *)
            echo -e "$Red Error: Invalid datatype (int|string) $Reset"
            return 1
        ;;
    esac
}

#################################
# Validate Integer Value
#################################
validate_int() {
    [[ $1 =~ ^[0-9]+$ ]]
}
