#!/bin/bash

# exit immediately if a command exits with a non-zero status
set -e

echo -e "\e[37m Creating certs directory..."
# make the directory /certs at the root of the project
mkdir -p certs

echo -e "\e[37m Generating root Certificate Authority Private Key..."
# create a 4096-bit RSA private key
openssl genrsa -out certs/ca.key 4096

echo -e "\e[37m Generating root Certificate Authority Public Key..."
# creates a self-signed certificate valid for 1 day
#   -key certs/ca.key -> Use this specific secret file to cryptographically sign the new certificate.
#       You are telling OpenSSL: "Use this specific secret file to cryptographically sign the new certificate."
#       The validity of the certificate relies entirely on this key. If you didn't provide this, OpenSSL would
#       try to generate a new key pair from scratch, or fail.
#   -out certs/ca.crt -> This specifies the filename and location for the Public Certificate you are creating.
#       This is the "Save As..." part of the command. Once the math is done, OpenSSL writes the final result to this file path.
#       This file (ca.crt) is what you will eventually distribute to your servers or clients.
#       It is safe to share publicly.
#   -subj "/CN=mTLS-Example-Root-CA" -> This sets the Subject (the identity) of the certificate owner.
#       It pre-fills the identification information so OpenSSL does not have to ask you interactively.
#       / is the seperator
#       CN stands for Common Name. This is the most important field—it's the human-readable name of the Authority or Server.
openssl req -new -x509 -days 1 -key certs/ca.key -out certs/ca.crt -subj "/CN=mTLS-Example-Root-CA"

echo -e "\e[32m Root Certificate Authority generated successfully!"
echo -e "\e[37m"