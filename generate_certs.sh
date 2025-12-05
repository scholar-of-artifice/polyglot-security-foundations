#!/bin/bash

# exit immediately if a command exits with a non-zero status
set -e

echo -e "\e[37m Creating certs directory..."
# make the directory /certs at the root of the project
mkdir -p certs

echo -e "\e[37m Generating root Certificate Authority Private Key..."
# create a 4096-bit RSA private key
openssl genrsa -out certs/ca.key 4096
# secure the key immediately
chmod 600 certs/ca.key

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

echo -e "\e[37m ------------------------ "
echo -e "\e[37m Processing service: overwhelming-minotaur"

echo -e "\e[37m Generating Private Key..."
# generate a new 4096-bit key for this service
openssl genrsa -out certs/overwhelming-minotaur.key 4096
# secure the key immediately
chmod 600 certs/overwhelming-minotaur.key

echo -e "\e[37m Generating Certificate Signing Request (CSR)..."
# create a request stating "i am overwhelming-minotaur"
# this does not create the certificate yet... it just asks for one
openssl req -new -key certs/overwhelming-minotaur.key -out certs/overwhelming-minotaur.csr -subj "/CN=overwhelming-minotaur"

echo -e "\e[37m Signing Certificates with Root Certificate Authority..."
# the certifcate authority (this computer) reviews the CSR and signs it with the root Private Key (ca.key).
# -CAcreateserial creates a serial number file if it does not exist (needed for tracking).
# we are giving this service certificate a validity of 1 day.
openssl x509 -req -in certs/overwhelming-minotaur.csr -CA certs/ca.crt -CAkey certs/ca.key -CAcreateserial -out certs/overwhelming-minotaur.crt -days 1

echo -e "\e[37m Distributing certs to service directory..."

# ensure the destination folder exists
mkdir -p overwhelming-minotaur/certs
# the service needs the root Certificate Authority to trust others
cp certs/ca.crt overwhelming-minotaur/certs/
# the service needs its own public certificate to prove who it is
cp certs/overwhelming-minotaur.crt overwhelming-minotaur/certs/
# the service needs its own private key to decrype messages intended for it
cp certs/overwhelming-minotaur.key overwhelming-minotaur/certs/
# secure the key immediately
# somtimes copy operations can reset permissions
chmod 600 overwhelming-minotaur/certs/overwhelming-minotaur.key

echo -e "\e[32m overwhelming-minotaur setup complete!"
echo -e "\e[37m"
