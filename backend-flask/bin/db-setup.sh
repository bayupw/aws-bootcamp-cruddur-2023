#! /usr/bin/bash
-e # stop if it fails at any point

CYAN='\033[1;36m'
NO_COLOR='\033[0m'
LABEL="Running db-setup.sh script ..."
printf "${CYAN}==== ${LABEL}${NO_COLOR}\n"

./db-drop.sh
./db-create.sh
./db-schema-load.sh
./db-seed.sh