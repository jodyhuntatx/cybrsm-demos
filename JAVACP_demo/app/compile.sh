#!/bin/bash
javac -cp /opt/CARKaim/sdk/javapasswordsdk.jar JavaPasswordRequest.java
echo "Main-Class: JavaPasswordRequest" > manifest.txt
echo "Class-Path: /opt/CARKaim/sdk/javapasswordsdk.jar" >> manifest.txt
jar cvfm JavaPasswordRequest.jar manifest.txt JavaPasswordRequest.class
rm manifest.txt

javac -cp /opt/CARKaim/sdk/javapasswordsdk.jar JavaPasswordQuery.java
echo "Main-Class: JavaPasswordQuery" > manifest.txt
echo "Class-Path: /opt/CARKaim/sdk/javapasswordsdk.jar" >> manifest.txt
jar cvfm JavaPasswordQuery.jar manifest.txt JavaPasswordQuery.class

rm manifest.txt *.class
