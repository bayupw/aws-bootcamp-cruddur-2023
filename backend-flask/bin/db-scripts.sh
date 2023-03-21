#!/bin/bash

while true; do
    # display the menu
    echo "Please choose an option:"
    echo "1. Execute db-connect.sh"
    echo "2. Execute db-create.sh"
    echo "3. Execute db-schema-load.sh"
    echo "8. Execute db-drop.sh"
    echo "9. Exit"

    # get the user's input
    read choice

    # execute the selected script or exit
    case $choice in
        1) ./db-connect.sh;;
        2) ./db-create.sh;;
        3) ./db-schema-load.sh;;
        8) ./db-drop.sh;;
        9) exit;;
        *) echo "Invalid choice. Please try again.";;
    esac
done
