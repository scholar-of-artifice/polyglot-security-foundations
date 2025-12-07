#!/bin/bash

# exit immediately if a command exits with a non-zero status
set -e

# ---
# define the container name
VAULT_CONTAINER="vault"
export VAULT_ADDR='http://127.0.0.1:8200'
export VAULT_TOKEN='root'

# check if vault is running yet...
echo "⏱️ waiting for vault..."
until vault status > /dev/null 2>&1; do
    echo "..."
    sleep 1
done

# ---
echo "🤐 enable PKI Secrets engine"
# mount the pki engine at the default path pki/
docker exec -e VAULT_TOKEN=$VAULT_TOKEN $VAULT_CONTAINER \
    vault secrets enable pki || echo "PKI already enabled"
# tune the engine to allow certificates to live up to 48 hours
docker exec -e VAULT_TOKEN=$VAULT_TOKEN $VAULT_CONTAINER \
    vault secrets tune -max-lease-ttl=48h pki
echo "PKI secrets engine set up..."

# ---
echo "📜 generate root Certificate Authority"
# generate root Certificate Authority
docker exec -e VAULT_TOKEN=$VAULT_TOKEN $VAULT_CONTAINER \
    vault write -field=certificate pki/root/generate/internal \
    common_name="mTLS-Example-Root-CA" \
    ttl=48h > root_ca.crt
echo "root Certificate Authority extracted to root_ca.crt on the host machine..."

# ---
echo "📋 configure CRL and Issuing URLs"
# this tells clients where to find the CA certificates...
# and Revocation List. Since this is in Docker...
# point to the container's internal hostname/IP
docker exec -e VAULT_TOKEN=$VAULT_TOKEN $VAULT_CONTAINER \
    vault write pki/config/urls \
    issuing_certificates="http://vault:8200/v1/pki/ca" \
    crl_distribution_points="http://vault:8200/v1/pki/crl"

# ---
echo "🐮 create a role for overwhelming-minotaur"
# this defines the rules for the certificate
# allowed_domains: restructs what CNs can be requested
# allow_subdomains=true: allows 'overwhelming-minotaur.foo', etc.
# max_ttl: the maximum time a cert issued by this role is valid (24 hours)
docker exec -e VAULT_TOKEN=$VAULT_TOKEN $VAULT_CONTAINER \
    vault write pki/roles/overwhelming-minotaur-role \
    allowed_domains="overwhelming-minotaur" \
    allow_subdomains=true \
    max_ttl="24h"

echo "✅ Vault PKI configured successfully!"