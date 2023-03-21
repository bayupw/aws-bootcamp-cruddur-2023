#!/bin/bash

while true; do
    # display the menu
    echo "Please choose an option:"
    
    echo "1. Execute db-connect.sh"
    echo "2. Execute db-sessions.sh"
    
    echo "10. Execute db-setup.sh"
    
    echo "21. Execute db-create.sh"
    echo "22. Execute db-schema-load.sh"
    echo "23. Execute db-seed.sh"

    echo "30. Execute db-drop.sh"
    
    echo "99. Exit"

    # get the user's input
    read choice

    # execute the selected script or exit
    case $choice in
        1) ./db-connect.sh;;
        2) ./db-sessions.sh;;
        10) ./db-setup.sh;;
        21) ./db-create.sh;;
        22) ./db-schema-load.sh;;
        23) ./db-seed.sh;;
        30) ./db-drop.sh;;
        99) exit;;
        *) echo "Invalid choice. Please try again.";;
    esac
done
