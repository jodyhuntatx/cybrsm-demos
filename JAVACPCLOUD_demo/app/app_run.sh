#!/bin/bash

source app.config

echo
echo "Query parameters:"
echo "================="
echo "APP_ID: $APP_ID"
echo "SAFE: $SAFE"
echo "OBJECT: $OBJECT"
echo "DEVICE_TYPE: $DEVICE_TYPE"
echo "POLICY_ID: $POLICY_ID"
echo "================="
echo
echo "Retrieve just the password:"
echo "Password:" $(java -jar JavaPasswordRequest.jar)
echo
echo "Retrieve multiple properties with query:"
java -jar JavaPasswordQuery.jar
echo
