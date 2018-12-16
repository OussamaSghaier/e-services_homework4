#!/bin/sh
while ! nc -z config-service 8888 ; do
    echo "Waiting for upcoming Config Service"
    sleep 2
done
while ! nc -z discovery-service 8761 ; do
    echo "Waiting for the Discovery Service"
    sleep 2
done
while ! nc -z proxy-service 9999 ; do
    echo "Waiting for the Proxy Service"
    sleep 2
done
java -jar /opt/lib/proxy-service-0.0.1-SNAPSHOT.jar
