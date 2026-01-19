#!/usr/bin/env bash

LC_COLLATE=C
shopt -s extglob

##################################
# Create Table
##################################
create_table() {

    valid_table=0
    while [[ $valid_table -eq 0 ]]; do
        read -p "Enter Table Name: " table_name
        table_name=$(tr " " "_" <<< "$table_name")

        if [[ -z "$table_name" ]]; then
            echo "Table name cannot be empty"
        elif [[ "$table_name" = [0-9]* ]]; then
            echo "Table name cannot start with number"
        elif [[ "$table_name" == "_" ]]; then
            echo "Invalid table name"
        elif [[ ! "$table_name" =~ ^[a-zA-Z][a-zA-Z0-9_]*$ ]]; then
            echo "Invalid characters in table name"
        elif [[ -f "$table_name.meta" ]]; then
            echo "Table already exists"
        else
            valid_table=1
        fi
    done

    valid_columns=0
    while [[ $valid_columns -eq 0 ]]; do
        read -p "Enter number of columns: " columns_count
        if [[ "$columns_count" =~ ^[0-9]+$ ]] && [[ $columns_count -gt 0 ]]; then
            valid_columns=1
        else
            echo "Enter valid positive number"
        fi
    done

    > "$table_name.meta"

    for ((i=1; i<=columns_count; i++)); do

        valid_column=0
        while [[ $valid_column -eq 0 ]]; do
            read -p "Column $i Name: " column_name
            column_name=$(tr " " "_" <<< "$column_name")

            if [[ -z "$column_name" ]]; then
                echo "Column name cannot be empty"
            elif [[ "$column_name" = [0-9]* ]]; then
                echo "Column name cannot start with number"
            elif [[ ! "$column_name" =~ ^[a-zA-Z][a-zA-Z0-9_]*$ ]]; then
                echo "Invalid column name"
            elif grep -q "^$column_name:" "$table_name.meta"; then
                echo "Column already exists"
            else
                valid_column=1
            fi
        done

        valid_type=0
        while [[ $valid_type -eq 0 ]]; do
            read -p "Datatype for $column_name (int|string): " datatype
            case "$datatype" in
                int|string) valid_type=1 ;;
                *) echo "Invalid datatype" ;;
            esac
        done

        echo "$column_name:$datatype" >> "$table_name.meta"
    done

    valid_pk=0
    while [[ $valid_pk -eq 0 ]]; do
        read -p "Primary Key Column: " primary_key
        if grep -q "^$primary_key:" "$table_name.meta"; then
            sed -i "s/^$primary_key:.*/&:PK/" "$table_name.meta"
            valid_pk=1
        else
            echo "Primary key must be one of the columns"
        fi
    done

    touch "$table_name.data"
    echo "Table '$table_name' created successfully"
}

##################################
# Insert Row
##################################
insert_row() {

    read -p "Enter Table Name: " table_name

    if [[ ! -f "$table_name.meta" ]]; then
        echo "Table not found"
    else
        row=""
        column_index=1

        while IFS=: read column datatype pk; do

            valid_value=0
            while [[ $valid_value -eq 0 ]]; do
                read -p "Enter value for $column: " value

                if [[ -z "$value" ]]; then
                    echo "Value cannot be empty"
                elif [[ "$value" == *"|"* ]]; then
                    echo "Value cannot contain |"
                elif [[ "$datatype" == "int" && ! "$value" =~ ^[0-9]+$ ]]; then
                    echo "Value must be integer"
                else
                    if [[ "$pk" == "PK" ]]; then
                        exists=$(cut -d'|' -f$column_index "$table_name.data" | grep -x "$value")
                        if [[ -n "$exists" ]]; then
                            echo "Primary key already exists"
                        else
                            valid_value=1
                        fi
                    else
                        valid_value=1
                    fi
                fi
            done

            row="$row|$value"
            ((column_index++))

        done < "$table_name.meta"

        echo "${row#|}" >> "$table_name.data"
        echo "Row inserted successfully"
    fi
}

##################################
# Select Table (Advanced)
##################################
select_table() {

    read -p "Enter Table Name: " table_name

    if [[ ! -f "$table_name.data" ]]; then
        echo "Table not found"
    else
        echo "Columns:"
        awk -F: '{print $1}' "$table_name.meta" | paste -sd '|'
        echo "---------------------"

        if [[ ! -s "$table_name.data" ]]; then
            echo "No data found"
        else
            column -t -s '|' "$table_name.data"
        fi

        echo ""
        echo "1) Select Column"
        echo "2) Search Value"
        echo "3) Exit"
        read -p "Choice: " choice

        case "$choice" in
            1)
                read -p "Column Number: " col
                if [[ "$col" =~ ^[0-9]+$ ]] && [[ $col -gt 0 ]]; then
                    awk -F'|' -v c="$col" '{print $c}' "$table_name.data"
                else
                    echo "Invalid column number"
                fi
            ;;
            2)
                read -p "Column Number: " col
                read -p "Search Value: " val
                awk -F'|' -v c="$col" -v v="$val" '$c==v {print NR,$0}' "$table_name.data"
            ;;
        esac
    fi
}

##################################
# Update Row
##################################
update_row() {

    read -p "Enter Table Name: " table_name

    if [[ ! -f "$table_name.data" ]]; then
        echo "Table not found"
    else
        pk_index=$(awk -F: '$3=="PK"{print NR}' "$table_name.meta")

        read -p "Primary Key Value: " pk_value
        read -p "Column Number: " col
        read -p "New Value: " new_value

        if [[ -z "$new_value" ]] || [[ "$new_value" == *"|"* ]]; then
            echo "Invalid value"
        else
            awk -F'|' -v pk="$pk_value" -v idx="$pk_index" -v c="$col" -v v="$new_value" '
            $idx==pk {$c=v}
            {print}
            ' OFS='|' "$table_name.data" > tmp && mv tmp "$table_name.data"

            echo "Row updated successfully"
        fi
    fi
}

##################################
# Delete Row
##################################
delete_row() {

    read -p "Enter Table Name: " table_name

    if [[ ! -f "$table_name.data" ]]; then
        echo "Table not found"
    else
        pk_index=$(awk -F: '$3=="PK"{print NR}' "$table_name.meta")

        read -p "Primary Key Value to delete: " pk_value
        awk -F'|' -v idx="$pk_index" -v pk="$pk_value" '$idx!=pk' "$table_name.data" > tmp && mv tmp "$table_name.data"
        echo "Row deleted successfully"
    fi
}

##################################
# Drop Table
##################################
drop_table() {

    read -p "Enter Table Name: " table_name

    if [[ ! -f "$table_name.meta" ]]; then
        echo "Table not found"
    else
        read -p "Type YES to confirm delete table: " confirm
        if [[ "$confirm" == "YES" || "$confirm" == "yes" ]]; then
            rm "$table_name.meta" "$table_name.data"
            echo "Table deleted successfully"
        else
            echo "Delete canceled"
        fi
    fi
}
