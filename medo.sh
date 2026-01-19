#!/usr/bin/bash

LC_COLLATE=C
shopt -s extglob

# ===== Colors =====
Reset="\033[0m"
Red="\033[31m"
Green="\033[32m"
Yellow="\033[33m"
Cyan="\033[36m"

DBMS_DIR="$HOME/DBMS_DEMO"

# ===== Create DBMS Folder =====
if [[ ! -d "$DBMS_DIR" ]]; then
    mkdir "$DBMS_DIR"
fi

echo -e "${Cyan}===== SIMPLE DBMS DEMO =====${Reset}"

# ==============================
# Main Menu
# ==============================
menu=("CreateDB" "ListDB" "ConnectDB" "DeleteDB" "Exit")

select choice in "${menu[@]}"
do
case $REPLY in

# ==============================
# Create Database
# ==============================
1)
    read -p "Enter Database Name: " db
    db=$(tr " " "_" <<< "$db")

    if [[ -z "$db" ]]; then
        echo -e "${Red}DB name can't be empty${Reset}"
    elif [[ "$db" = [0-9]* ]]; then
        echo -e "${Red}DB name can't start with number${Reset}"
    elif [[ "$db" == "_" ]]; then
        echo -e "${Red}Invalid DB name${Reset}"
    elif [[ ! "$db" =~ ^[a-zA-Z][a-zA-Z0-9_]*$ ]]; then
        echo -e "${Red}Invalid characters${Reset}"
    elif [[ -d "$DBMS_DIR/$db" ]]; then
        echo -e "${Red}DB already exists${Reset}"
    else
        mkdir "$DBMS_DIR/$db"
        echo -e "${Green}Database Created${Reset}"
    fi
;;

# ==============================
# List Databases
# ==============================
2)
    echo -e "${Cyan}Databases:${Reset}"
    ls -F "$DBMS_DIR" | grep '/' | tr -d '/'
;;

# ==============================
# Connect Database
# ==============================
3)
    read -p "Enter DB Name: " db
    dbPath="$DBMS_DIR/$db"

    if [[ ! -d "$dbPath" ]]; then
        echo -e "${Red}Database not found${Reset}"
    else
        echo -e "${Green}Connected to $db${Reset}"

        tableMenu=("CreateTable" "Insert" "Select" "Update" "Delete" "DropTable" "Back")

        select tableChoice in "${tableMenu[@]}"
        do
        case $REPLY in

        # ==============================
        # Create Table
        # ==============================
        1)
            read -p "Table Name: " table
            table=$(tr " " "_" <<< "$table")

            if [[ -f "$dbPath/$table.meta" ]]; then
                echo -e "${Red}Table exists${Reset}"
            else
                read -p "Number of columns: " cols

                if [[ ! "$cols" =~ ^[0-9]+$ || "$cols" -lt 1 ]]; then
                    echo -e "${Red}Invalid number${Reset}"
                else
                    colNames=""
                    colTypes=""

                    for ((i=1;i<=cols;i++)); do
                        read -p "Column $i name: " cname
                        read -p "Type (int/string): " ctype

                        if [[ "$ctype" != "int" && "$ctype" != "string" ]]; then
                            echo -e "${Red}Invalid type${Reset}"
                            ((i--))
                        else
                            colNames+="$cname:"
                            colTypes+="$ctype:"
                        fi
                    done

                    read -p "Primary Key Column Name: " pk

                    echo "${colNames%:}" > "$dbPath/$table.meta"
                    echo "${colTypes%:}" >> "$dbPath/$table.meta"
                    echo "$pk" >> "$dbPath/$table.meta"
                    touch "$dbPath/$table.data"

                    echo -e "${Green}Table Created${Reset}"
                fi
            fi
        ;;

        # ==============================
        # Insert
        # ==============================
        2)
            read -p "Table Name: " table

            if [[ ! -f "$dbPath/$table.meta" ]]; then
                echo -e "${Red}Table not found${Reset}"
            else
                cols=$(sed -n '1p' "$dbPath/$table.meta")
                types=$(sed -n '2p' "$dbPath/$table.meta")
                pk=$(sed -n '3p' "$dbPath/$table.meta")

                IFS=':' read -ra cArr <<< "$cols"
                IFS=':' read -ra tArr <<< "$types"

                row=""
                for ((i=0;i<${#cArr[@]};i++)); do
                    read -p "${cArr[$i]} (${tArr[$i]}): " val

                    if [[ "${tArr[$i]}" == "int" && ! "$val" =~ ^[0-9]+$ ]]; then
                        echo -e "${Red}Invalid integer${Reset}"
                        ((i--))
                    else
                        row+="$val:"
                    fi
                done

                echo "${row%:}" >> "$dbPath/$table.data"
                echo -e "${Green}Row Inserted${Reset}"
            fi
        ;;

        # ==============================
        # Select
        # ==============================
        3)
            read -p "Table Name: " table
            if [[ -f "$dbPath/$table.data" ]]; then
                cat -n "$dbPath/$table.data"
            else
                echo -e "${Red}Table not found${Reset}"
            fi
        ;;

        # ==============================
        # Update
        # ==============================
        4)
            read -p "Table Name: " table
            read -p "Line Number: " ln
            read -p "New Row (same format): " newRow

            sed -i "${ln}s/.*/$newRow/" "$dbPath/$table.data"
            echo -e "${Green}Row Updated${Reset}"
        ;;

        # ==============================
        # Delete
        # ==============================
        5)
            read -p "Table Name: " table
            read -p "Line Number: " ln

            sed -i "${ln}d" "$dbPath/$table.data"
            echo -e "${Green}Row Deleted${Reset}"
        ;;

        # ==============================
        # Drop Table
        # ==============================
        6)
            read -p "Table Name: " table
            rm -f "$dbPath/$table.meta" "$dbPath/$table.data"
            echo -e "${Green}Table Dropped${Reset}"
        ;;

        7) break ;;
        *) echo "Invalid choice" ;;
        esac
        done
    fi
;;

# ==============================
# Delete DB
# ==============================
4)
    read -p "DB Name: " db
    rm -rf "$DBMS_DIR/$db"
    echo -e "${Green}Database Deleted${Reset}"
;;

5)
    echo -e "${Yellow}Goodbye${Reset}"
    break
;;

*)
    echo -e "${Red}Invalid Option${Reset}"
;;
esac
done
