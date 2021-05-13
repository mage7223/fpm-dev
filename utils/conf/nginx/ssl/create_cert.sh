#!/bin/bash
ACTION=$1

if [ "$ACTION" == "test" ]; then
    openssl x509 -in cert.pem -noout --text
else
    openssl req -x509 -nodes -days 730 -newkey rsa:2048 -keyout cert.pem -out cert.pem -config req.conf -extensions 'v3_req'
fi
