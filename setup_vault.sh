#!/bin/bash

# exit immediately if a command exits with a non-zero status
set -e

# ---
echo "🧹 cleaning up stale credentials..."
rm -rf /certs/*
rm -rf /secrets/*

# ---
: "${VAULT_ADDR:?VAULT_ADDR environment variable is required}"
export VAULT_TOKEN='root'
# define the service names from environment variables
OVERWHELMING_MINOTAUR_HOST="${OVERWHELMING_MINOTAUR_HOSTNAME?OVERWHELMING_MINOTAUR_HOSTNAME is not set!}"
SIEGE_LEVIATHAN_HOST="${SIEGE_LEVIATHAN_HOSTNAME?SIEGE_LEVIATHAN_HOSTNAME is not set!}"
STOIC_SPHYNX_HOST="${STOIC_SPHYNX_HOSTNAME?STOIC_SPHYNX_HOSTNAME is not set!}"
EAGER_GRYPHON_HOST="${EAGER_GRYPHON_HOSTNAME?EAGER_GRYPHON_HOSTNAME is not set!}"

VAULT_HOST="${VAULT_HOSTNAME?VAULT_HOSTNAME is not set!}"
VAULT_P="${VAULT_PORT?VAULT_PORT is not set!}"

echo "🔧 configuring Vault for:"
echo "  - Vault: ${VAULT_HOST}:${VAULT_P}"
echo "  - overwhelming-minotaur: ${OVERWHELMING_MINOTAUR_HOST}"
echo "  - siege-leviathan: ${SIEGE_LEVIATHAN_HOST}"

# make a directory to store the secrets
mkdir -p secrets/ca secrets/${SIEGE_LEVIATHAN_HOST} secrets/${OVERWHELMING_MINOTAUR_HOST} secrets/${STOIC_SPHYNX_HOST} secrets/${EAGER_GRYPHON_HOST}

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
    ttl=48h > secrets/ca/root_ca.crt
echo "root Certificate Authority extracted to root_ca.crt on the host machine..."

# ---
echo "📋 configure CRL and Issuing URLs"
# this tells clients where to find the CA certificates...
# and Revocation List. Since this is in Docker...
# point to the container's internal hostname/IP
vault write pki/config/urls \
    issuing_certificates="http://${VAULT_HOST}:${VAULT_P}/v1/pki/ca" \
    crl_distribution_points="http://${VAULT_HOST}:${VAULT_P}/v1/pki/crl"

# ---
echo "🐮 create a role for ${OVERWHELMING_MINOTAUR_HOST}"
# this defines the rules for the certificate
# allowed_domains: restructs what CNs can be requested
# allow_subdomains=true: allows 'overwhelming-minotaur.foo', etc.
# max_ttl: the maximum time a cert issued by this role is valid (24 hours)
vault write pki/roles/${OVERWHELMING_MINOTAUR_HOST}-role \
    allowed_domains="${OVERWHELMING_MINOTAUR_HOST}" \
    allow_subdomains=true \
    allow_bare_domains=true\
    max_ttl="24h"

# ---
echo "🐍 create a role for ${SIEGE_LEVIATHAN_HOST}"
# this defines the rules for the certificate
# allowed_domains: restructs what CNs can be requested
# allow_subdomains=true: allows 'siege-leviathan.foo', etc.
# max_ttl: the maximum time a cert issued by this role is valid (24 hours)
vault write pki/roles/${SIEGE_LEVIATHAN_HOST}-role \
    allowed_domains="${SIEGE_LEVIATHAN_HOST}" \
    allow_subdomains=true \
    allow_bare_domains=true\
    max_ttl="24h"

# ---
echo " create a role for ${STOIC_SPHYNX_HOST}"
# this defines the rules for the certificate
# allowed_domains: restructs what CNs can be requested
# allow_subdomains=true: allows 'stoic_sphynx.foo', etc.
# max_ttl: the maximum time a cert issued by this role is valid (24 hours)
vault write pki/roles/${STOIC_SPHYNX_HOST}-role \
    allowed_domains="${STOIC_SPHYNX_HOST}" \
    allow_subdomains=true \
    allow_bare_domains=true\
    max_ttl="24h"

# ---
echo " create a role for ${EAGER_GRYPHON_HOST}"
# this defines the rules for the certificate
# allowed_domains: restructs what CNs can be requested
# allow_subdomains=true: allows 'eager_gryphon.foo', etc.
# max_ttl: the maximum time a cert issued by this role is valid (24 hours)
vault write pki/roles/${EAGER_GRYPHON_HOST}-role \
    allowed_domains="${EAGER_GRYPHON_HOST}" \
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
vault policy write ${OVERWHELMING_MINOTAUR_HOST}-policy - << EOF
path "pki/issue/${OVERWHELMING_MINOTAUR_HOST}-role" {
    capabilities = ["create", "update"]
}
EOF

# create a policy that allows 'update' on the specific PKI role
# write the policy definition to a temporary file inside the container then apply it
vault policy write ${SIEGE_LEVIATHAN_HOST}-policy - << EOF
path "pki/issue/${SIEGE_LEVIATHAN_HOST}-role" {
    capabilities = ["create", "update"]
}
EOF

# create the AppRole and attach the policy
vault write auth/approle/role/${OVERWHELMING_MINOTAUR_HOST}-auth-role \
    token_policies="${OVERWHELMING_MINOTAUR_HOST}-policy" \
    token_ttl=1h \
    token_max_ttl=4h


# create the AppRole and attach the policy
vault write auth/approle/role/${SIEGE_LEVIATHAN_HOST}-auth-role \
    token_policies="${SIEGE_LEVIATHAN_HOST}-policy" \
    token_ttl=1h \
    token_max_ttl=4h

# create the AppRole and attach the policy
vault write auth/approle/role/${STOIC_SPHYNX_HOST}-auth-role \
    token_policies="${STOIC_SPHYNX_HOST}-policy" \
    token_ttl=1h \
    token_max_ttl=4h

# create the AppRole and attach the policy
vault write auth/approle/role/${EAGER_GRYPHON_HOST}-auth-role \
    token_policies="${EAGER_GRYPHON_HOST}-policy" \
    token_ttl=1h \
    token_max_ttl=4h

# fetch the RoleID and SecretID and save them locally...
# the agen will read these files to log in
echo "Fetching ${OVERWHELMING_MINOTAUR_HOST} Credentials"
vault read -field=role_id auth/approle/role/${OVERWHELMING_MINOTAUR_HOST}-auth-role/role-id > secrets/${OVERWHELMING_MINOTAUR_HOST}/role_id
vault write -force -field=secret_id auth/approle/role/${OVERWHELMING_MINOTAUR_HOST}-auth-role/secret-id > secrets/${OVERWHELMING_MINOTAUR_HOST}/secret_id
echo "Fetching ${SIEGE_LEVIATHAN_HOST} Credentials"
vault read -field=role_id auth/approle/role/${SIEGE_LEVIATHAN_HOST}-auth-role/role-id > secrets/${SIEGE_LEVIATHAN_HOST}/role_id
vault write -force -field=secret_id auth/approle/role/${SIEGE_LEVIATHAN_HOST}-auth-role/secret-id > secrets/${SIEGE_LEVIATHAN_HOST}/secret_id
echo "Fetching ${STOIC_SPHYNX_HOST} Credentials"
vault read -field=role_id auth/approle/role/${STOIC_SPHYNX_HOST}-auth-role/role-id > secrets/${STOIC_SPHYNX_HOST}/role_id
vault write -force -field=secret_id auth/approle/role/${STOIC_SPHYNX_HOST}-auth-role/secret-id > secrets/${STOIC_SPHYNX_HOST}/secret_id
echo "Fetching ${EAGER_GRYPHON_HOST} Credentials"
vault read -field=role_id auth/approle/role/${EAGER_GRYPHON_HOST}-auth-role/role-id > secrets/${EAGER_GRYPHON_HOST}/role_id
vault write -force -field=secret_id auth/approle/role/${EAGER_GRYPHON_HOST}-auth-role/secret-id > secrets/${EAGER_GRYPHON_HOST}/secret_id


echo "✅ Vault AppRole configured successfully!"
