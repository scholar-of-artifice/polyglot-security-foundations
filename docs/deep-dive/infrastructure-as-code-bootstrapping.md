# Infrastructure as Code (IaC) Bootstrapping

> *If opportunity doesn't knock, build a door. -Milton Berle*

In this article, you will get a brief rundown of `setup_-_vault.sh`.
You will get an explanation of the important parts and their purpose.
This way, you may understand what is required to setup Vault for cloud deployments.

## How do we bootstrap a Root CA and an Intermediate
In this project, the entire Public Key Infrastructure (PKI) is ephemeral.
Every time the environment starts, a fresh Root Certificate Authority (CA) is generated.
This is handled by the `setup_vault.sh` script.
It automates the configuration of Hashicorp Vault for local use.

## The Bootstrapping Process

The script performs the following idempotent steps to ensure a clean state.

### 1) Clean Slate Protocol
Remove any potentially stale credentials to ensure no previous state leaks into the new session or any extra rejected requests.

Relevant code ➡️ [here](https://github.com/scholar-of-artifice/polyglot-security-foundations/blob/dbd1732782b1edad3f233c49eede0a98d13361c5/setup_vault.sh#L7-L9)

### 2) Enable Public Key Infrastructure (PKI) Engine
Enable the PKI secrets engine at the default path (`pki/`).
A PKI Engine is a system component that automates the creation, management, issuance and revocation of certificates and keys. It acts as the CA to establish trust, secure communication and verify identities for application services.

Relevant code ➡️ [here](https://github.com/scholar-of-artifice/polyglot-security-foundations/blob/dbd1732782b1edad3f233c49eede0a98d13361c5/setup_vault.sh#L39-L44)

### 3) Generate Root CA
We generate an internal Root CA specifically for this environment.
This certificate is extracted to the host machine so it can be loaded by the application servers as the `Trust Anchor`.

Relevant code ➡️ [here](https://github.com/scholar-of-artifice/polyglot-security-foundations/blob/dbd1732782b1edad3f233c49eede0a98d13361c5/setup_vault.sh#L46-L52)

### 4) Role Definition
We define distinct roles for each service.
Roles act as guardrails and place constraints such as:

`overwhelming-minotaur` ➡️ [here](https://github.com/scholar-of-artifice/polyglot-security-foundations/blob/dbd1732782b1edad3f233c49eede0a98d13361c5/setup_vault.sh#L63-L73)

#### Allowed Domains 
A service cannot request for a domain it does not own.

#### Time To Live (TTL) 
The certificates are strictly limited to 24 hours but feel free to change this for your experimentation.

## Authentication
Instead of using root tokens, services authenticate using the **App Role** method, which is optimized for machine-machine authentication.

You can find out more about auto-authentication here: https://developer.hashicorp.com/vault/docs/agent-and-proxy/autoauth

### Policies
The script generates Vault policies that grant permission to `update` certificates only against the specific role assigned to that service.

### Credential Delivery
The script retrieves the `role_id` and `secret_id` for each service and writes them to a shared volume (`secrets/`).
This simulates a secure credential delivery mechanism that the `vault-agent`s will later consume.

## Resources

https://www.youtube.com/embed/klyAhaklGNU?si=s_3gT2tablCOw2jY
