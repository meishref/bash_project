#!/usr/bin/env bash
shopt -s extglob

# ===== Colors =====
Red="\e[31m"
Green="\e[32m"
Yellow="\e[33m"
Reset="\e[0m"

# ===== DBMS Root =====
DBMS_DIR="$HOME/.DBMS"

#################################
# Validate Name (DB / Table / Column)
#################################
validate_name() {

    name="$1"
    type="$2"
    valid=1

    if [[ -z "$name" ]]; then
        echo -e "$Red Error: $type name cannot be empty $Reset"
        valid=0
    elif [[ "$name" = [0-9]* ]]; then
        echo -e "$Red Error: $type name cannot start with number $Reset"
        valid=0
    elif [[ "$name" == "_" ]]; then
        echo -e "$Red Error: $type name cannot be '_' $Reset"
        valid=0
    elif [[ ! "$name" =~ ^[a-zA-Z][a-zA-Z0-9_]*$ ]]; then
        echo -e "$Red Error: Invalid $type name $Reset"
        valid=0
    fi

    if [[ $valid -eq 1 ]]; then
        echo "VALID"
    else
        echo "INVALID"
    fi
}

#################################
# Validate Datatype
#################################
validate_datatype() {

    datatype="$1"
    valid=1

    case "$datatype" in
        int|string)
            valid=1
        ;;
        *)
            echo -e "$Red Error: Invalid datatype (int|string) $Reset"
            valid=0
        ;;
    esac

    if [[ $valid -eq 1 ]]; then
        echo "VALID"
    else
        echo "INVALID"
    fi
}

#################################
# Validate Integer
#################################
validate_int() {

    number="$1"

    if [[ "$number" =~ ^[0-9]+$ ]]; then
        echo "VALID"
    else
        echo -e "$Red Error: Not a valid integer $Reset"
        echo "INVALID"
    fi
}
