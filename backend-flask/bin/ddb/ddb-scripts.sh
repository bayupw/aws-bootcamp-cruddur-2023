#!/bin/bash

while true; do
    # display the menu
    echo "Please choose an option:"
    
    echo "1. Execute list-tables.sh"
    echo "2. Execute scan.sh"
    
    echo "11. Execute schema-load.sh"
    echo "12. Execute seed.sh"
    
    echo "21. Execute get-conversation.sh"
    echo "22. Execute list-conversations.sh"

    echo "30. Execute drop-table.sh"
    

    echo "99. Exit"

    # get the user's input
    read choice

    # execute the selected script or exit
    case $choice in
        1) ./list-tables.sh;;
        2) ./scan.sh;;
        11) ./schema-load.sh;;
        12) ./seed.sh;;
        21) ./patterns/get-conversation.sh;;
        22) ./patterns/list-conversations.sh;;
        30) ./drop-table.sh;;
        99) exit;;
        *) echo "Invalid choice. Please try again.";;
    esac
done
