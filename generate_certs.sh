#!/bin/bash

# exit immediately if a command exits with a non-zero status
set -e

echo -e "\e[37m Creating certs directory..."
mkdir -p certs

echo -e "\e[37m Generating root Certificate Authority Private Key..."
openssl genrsa -out certs/ca.key 4096

echo -e "\e[37m Generating root Certificate Authority Public Key..."
openssl req -new -x509 -days 1 -key certs/ca.key -out certs/ca.crt -subj "/CN=mTLS-Example-Root-CA"

echo -e "\e[32m Root Certificate Authority generated successfully!"
echo -e "\e[37m"