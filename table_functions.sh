#!/usr/bin/env bash

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$PROJECT_DIR/utils.sh"

##################################
# Create Table
##################################
create_table() {

    read -p "Table Name: " table_name
    validate_name "$table_name" "Table" || return

    [[ -f "$table_name.data" ]] && echo "Table Exists" && return

    read -p "Columns Count: " columns_count
    validate_int "$columns_count" || { echo "Invalid number"; return; }

    > "$table_name.meta"

    for ((column_index=1; column_index<=columns_count; column_index++)); do

        read -p "Column $column_index Name: " column_name
        validate_name "$column_name" "Column" || return

        read -p "Datatype (int|string): " datatype
        validate_datatype "$datatype" || return

        echo "$column_name:$datatype" >> "$table_name.meta"
    done

    read -p "Primary Key Column: " primary_key
    grep -q "^$primary_key:" "$table_name.meta" || {
        echo "Primary Key Not Found"
        return
    }

    sed -i "s/^$primary_key:.*/&:PK/" "$table_name.meta"

    touch "$table_name.data"
    echo "Table Created Successfully"
}

##################################
# Insert Row
##################################
insert_row() {

    read -p "Table Name: " table_name
    [[ ! -f "$table_name.meta" ]] && echo "Table Not Found" && return

    row_data=""
    column_index=1

    while IFS=: read column_name datatype primary_key_flag; do

        read -p "Enter $column_name: " value

        [[ $datatype == "int" ]] && ! validate_int "$value" && {
            echo "Invalid Integer Value"
            return
        }

        if [[ $primary_key_flag == "PK" ]]; then
            cut -d'|' -f$column_index "$table_name.data" | grep -x "$value" >/dev/null && {
                echo "Primary Key Exists"
                return
            }
        fi

        row_data+="$value|"
        ((column_index++))

    done < "$table_name.meta"

    echo "${row_data%|}" >> "$table_name.data"
    echo "Row Inserted"
}

##################################
# Select Table
##################################
select_table() {

    read -p "Table Name: " table_name
    [[ ! -f "$table_name.data" ]] && echo "Table Not Found" && return

    awk -F: '{print $1}' "$table_name.meta" | paste -sd '|'
    echo "-------------------------"
    column -t -s '|' "$table_name.data"
}

##################################
# Delete Row
##################################
delete_row() {

    read -p "Table Name: " table_name
    read -p "Primary Key Value: " primary_key_value

    sed -i "/^$primary_key_value|/d" "$table_name.data"
    echo "Row Deleted"
}

##################################
# Update Row
##################################
update_row() {

    read -p "Table Name: " table_name
    read -p "Primary Key Value: " primary_key_value
    read -p "Column Number: " column_number
    read -p "New Value: " new_value

    validate_int "$column_number" || { echo "Invalid Column Number"; return; }

    awk -F'|' -v pk="$primary_key_value" -v col="$column_number" -v val="$new_value" '
        $1==pk { $col=val }
        { print }
    ' OFS='|' "$table_name.data" > tmp && mv tmp "$table_name.data"

    echo "Row Updated"
}
