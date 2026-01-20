#!/usr/bin/env bash

LC_COLLATE=C
shopt -s extglob


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


insert_row() {

    read -p "Enter Table Name: " table_name

    if [[ ! -f "$table_name.meta" ]]; then
        echo "Table not found"
        return
    fi

    row=""
    column_index=1

   
    while IFS=':' read -r column datatype pk; do

       
        if [[ -z "$column" || -z "$datatype" ]]; then
            continue
        fi

        valid_value=0
        while [[ $valid_value -eq 0 ]]; do

           
            read -p "Enter value for $column: " value </dev/tty

            if [[ -z "$value" ]]; then
                echo "Value cannot be empty"

            elif [[ "$value" == *"|"* ]]; then
                echo "Value cannot contain |"

            elif [[ "$datatype" == "int" && ! "$value" =~ ^[0-9]+$ ]]; then
                echo "Value must be integer"

            elif [[ "$pk" == "PK" ]]; then
                exists=$(cut -d'|' -f$column_index "$table_name.data" 2>/dev/null | grep -x "$value")
                if [[ -n "$exists" ]]; then
                    echo "Primary key already exists"
                else
                    valid_value=1
                fi

            else
                valid_value=1
            fi
        done

        row="$row|$value"
        ((column_index++))

    done < "$table_name.meta"

    echo "${row#|}" >> "$table_name.data"
    echo "Row inserted successfully"
}



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


update_row() {

    read -p "Enter Table Name: " table_name

    if [[ ! -f "$table_name.meta" || ! -f "$table_name.data" ]]; then
        echo "Table not found"
        return
    fi

   
    pk_index=$(awk -F: '$3=="PK"{print NR}' "$table_name.meta")

    if [[ -z "$pk_index" ]]; then
        echo "Primary key not defined"
        return
    fi

    read -p "Enter Primary Key value: " pk_value </dev/tty

   
    row_num=$(awk -F'|' -v idx="$pk_index" -v pk="$pk_value" '$idx==pk {print NR}' "$table_name.data")

    if [[ -z "$row_num" ]]; then
        echo "Row not found"
        return
    fi

    echo "Current Row:"
    sed -n "${row_num}p" "$table_name.data"

    
    echo "Columns:"
    awk -F: '{print NR ") " $1}' "$table_name.meta"

    read -p "Choose column number to update: " col_num </dev/tty

    if [[ ! "$col_num" =~ ^[0-9]+$ ]]; then
        echo "Invalid column number"
        return
    fi

    
    if [[ "$col_num" -eq "$pk_index" ]]; then
        echo "Cannot update Primary Key"
        return
    fi

   
    datatype=$(awk -F: -v n="$col_num" 'NR==n {print $2}' "$table_name.meta")

    read -p "Enter new value: " new_value </dev/tty

    if [[ -z "$new_value" ]]; then
        echo "Value cannot be empty"
        return
    fi

    if [[ "$new_value" == *"|"* ]]; then
        echo "Value cannot contain |"
        return
    fi

    if [[ "$datatype" == "int" && ! "$new_value" =~ ^[0-9]+$ ]]; then
        echo "Value must be integer"
        return
    fi

   
    awk -F'|' -v r="$row_num" -v c="$col_num" -v v="$new_value" '
        NR==r {$c=v}
        {print}
    ' OFS='|' "$table_name.data" > tmp && mv tmp "$table_name.data"

    echo "Row updated successfully"
}



delete_row() {

    read -p "Enter Table Name: " table_name

    if [[ ! -f "$table_name.meta" || ! -f "$table_name.data" ]]; then
        echo "Table not found"
        return
    fi

    if [[ ! -s "$table_name.data" ]]; then
        echo "Table is empty"
        return
    fi

    echo "Current Data:"
    cat -n "$table_name.data"

  
    pk_index=$(awk -F: '$3=="PK"{print NR}' "$table_name.meta")

    if [[ -z "$pk_index" ]]; then
        echo "Primary key not defined"
        return
    fi

    echo ""
    echo "1) Delete by Primary Key"
    echo "2) Delete all rows"
    read -p "Choice: " choice </dev/tty

    case "$choice" in
        1)
            read -p "Enter Primary Key value: " pk_value </dev/tty

            row_num=$(awk -F'|' -v idx="$pk_index" -v pk="$pk_value" '
                $idx==pk {print NR}
            ' "$table_name.data")

            if [[ -z "$row_num" ]]; then
                echo "Row not found"
                return
            fi

            read -p "Confirm delete (YES): " confirm </dev/tty
            if [[ "$confirm" == "YES" ]]; then
                sed -i "${row_num}d" "$table_name.data"
                echo "Row deleted successfully"
            else
                echo "Delete cancelled"
            fi
            ;;
        2)
            read -p "Delete ALL rows? Type YES: " confirm </dev/tty
            if [[ "$confirm" == "YES" ]]; then
                > "$table_name.data"
                echo "All rows deleted"
            else
                echo "Cancelled"
            fi
            ;;
        *)
            echo "Invalid choice"
            ;;
    esac
}


drop_table() {

    read -p "Enter Table Name: " table_name

    if [[ ! -f "$table_name.meta" || ! -f "$table_name.data" ]]; then
        echo "Table not found"
        return
    fi

    rows=$(wc -l < "$table_name.data" 2>/dev/null)

    echo "WARNING!"
    echo "This will delete table '$table_name' and $rows row(s)."

    read -p "Type table name to confirm: " confirm </dev/tty

    if [[ "$confirm" == "$table_name" ]]; then
        rm -f "$table_name.meta" "$table_name.data"
        echo "Table '$table_name' dropped successfully"
    else
        echo "Cancelled"
    fi
}
