#!/bin/bash
echo
echo "secrets.yml:"
echo "============"
cat secrets.yml
echo "============"
echo
echo "Executing query..."
echo
summon -p ./summon-ccp.sh ./secrets_echo.sh
