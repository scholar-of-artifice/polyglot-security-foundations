#!/bin/bash

# exit immediately if a command exits with a non-zero status
set -e

# ---
# define the container name
export VAULT_ADDR='http://vault:8200'
VAULT_CONTAINER="vault"
export VAULT_TOKEN='root'
# make a directory to store the secrets
mkdir -p secrets

# check if vault is running yet...
echo "⏱️ waiting for vault..."
until vault status > /dev/null 2>&1; do
    echo "..."
    sleep 1
done

# ---
echo "🤐 enable PKI Secrets engine"
# mount the pki engine at the default path pki/
vault secrets enable pki || echo "PKI already enabled"
# tune the engine to allow certificates to live up to 48 hours
vault secrets tune -max-lease-ttl=48h pki
echo "PKI secrets engine set up..."

# ---
echo "📜 generate root Certificate Authority"
# generate root Certificate Authority
vault write -field=certificate pki/root/generate/internal \
    common_name="mTLS-Example-Root-CA" \
    ttl=48h > secrets/root_ca.crt
echo "root Certificate Authority extracted to root_ca.crt on the host machine..."

# ---
echo "📋 configure CRL and Issuing URLs"
# this tells clients where to find the CA certificates...
# and Revocation List. Since this is in Docker...
# point to the container's internal hostname/IP
vault write pki/config/urls \
    issuing_certificates="http://vault:8200/v1/pki/ca" \
    crl_distribution_points="http://vault:8200/v1/pki/crl"

# ---
echo "🐮 create a role for overwhelming-minotaur"
# this defines the rules for the certificate
# allowed_domains: restructs what CNs can be requested
# allow_subdomains=true: allows 'overwhelming-minotaur.foo', etc.
# max_ttl: the maximum time a cert issued by this role is valid (24 hours)
vault write pki/roles/overwhelming-minotaur-role \
    allowed_domains="overwhelming-minotaur" \
    allow_subdomains=true \
    allow_bare_domains=true\
    max_ttl="24h"

# ---
echo "🐍 create a role for siege-leviathan"
# this defines the rules for the certificate
# allowed_domains: restructs what CNs can be requested
# allow_subdomains=true: allows 'siege-leviathan.foo', etc.
# max_ttl: the maximum time a cert issued by this role is valid (24 hours)
vault write pki/roles/siege-leviathan-role \
    allowed_domains="siege-leviathan" \
    allow_subdomains=true \
    allow_bare_domains=true\
    max_ttl="24h"

echo "✅ Vault PKI configured successfully!"

# ---
echo "🤝 configure AppRole Authentication"
# enable AppRole auth method
vault auth enable approle || echo "AppRole already enabled"
# create a policy that allows 'update' on the specific PKI role
# write the policy definition to a temporary file inside the container then apply it
vault policy write minotaur-policy - << EOF
path "pki/issue/overwhelming-minotaur-role" {
    capabilities = ["create", "update"]
}
EOF

# create the AppRole and attach the policy
vault write auth/approle/role/minotaur-auth-role \
    token_policies="minotaur-policy" \
    token_ttl=1h \
    token_max_ttl=4h
# fetch the RoleID and SecretID and save them locally...
# the agen will read these files to log in
echo "Fetching RoleID"
vault read -field=role_id auth/approle/role/minotaur-auth-role/role-id > secrets/role_id
echo "Fetching SecretID"
vault write -force -field=secret_id auth/approle/role/minotaur-auth-role/secret-id > secrets/secret_id

echo "✅ Vault AppRole configured successfully!"
