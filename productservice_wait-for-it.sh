#!/bin/sh
while ! nc -z config-service 8888 ; do
    echo "Waiting for the Config Service"
    sleep 3
done
while ! nc -z discovery-service 8761 ; do
    echo "Waiting for the Discovery Service"
    sleep 3
done
java -jar /opt/lib/product-service-0.0.1-SNAPSHOT.jar
