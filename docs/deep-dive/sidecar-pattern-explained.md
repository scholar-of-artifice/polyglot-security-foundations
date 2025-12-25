# Sidecar Pattern Explained

> *Help each other, encourage each other, lift each other up. -Ed Reed*

In this article, you will learn about the sidecar architecture pattern and its relation to `vault-agent`.

## What is the Sidecar Pattern?

The Sidecar architecture pattern involves deploying a auxiliary application alongside a target (primary) application. These application live in distinct containers but are networked together.

In this project, a **Vault Agent** sidecar runs next to every service.

### Example
> `vault-agent-overwhelming-minotaur` runs as a sidecar for `overwhelming-minotaur`.

The sidecar handles the complex task of authentication and secret retrieval, allowing the main application to remain ignorant of Vault entirely.

## What are the key components for implementing a Sidecar

The exact things required for a sidecar, depend on the role of that sidecar. In this system, we are chiefly concerned about getting credentials to apps and rotating those keys. For this use case, we require the following:

### 1) Shared Volume
The agent needs a place to write credentials. The application needs a place to read credentials.
Here is an example for the `vault-agent-overwhelming-minotaur` and app `overwhelming-minotaur` do this: 
➡️ [`vault-agent-overwhelming-minotaur`](https://github.com/scholar-of-artifice/polyglot-security-foundations/blob/e6ddcb907e770a6d68510799f014402e6eb851a4/docker-compose.yaml#L48-L50)
➡️ [`overwhelming-minotaur`](https://github.com/scholar-of-artifice/polyglot-security-foundations/blob/e6ddcb907e770a6d68510799f014402e6eb851a4/docker-compose.yaml#L170-L172)

### 2) Required Information
The **Vault Agent** relies on the **Vault** app. Therefore, we need to perform a health check which can be handled gracefully via `docker-compose` ➡️ [here](https://github.com/scholar-of-artifice/polyglot-security-foundations/blob/e6ddcb907e770a6d68510799f014402e6eb851a4/docker-compose.yaml#L55-L66)

### 3) Lifecycle Dependencies
The main application must wait for the sidecar to be "healthy" before starting.
This can be handled via `docker-compose` ➡️ [here](https://github.com/scholar-of-artifice/polyglot-security-foundations/blob/e6ddcb907e770a6d68510799f014402e6eb851a4/docker-compose.yaml#L173-L175)

### 4) Template Rendering
The Vault Agent uses a template which is defined in `agent-config.hcl`. This will apply a defined format of the raw secret data from Vault into a standard PEM format that most modern programming languages can unpack.
Here is the specific code  ➡️ [here](https://github.com/scholar-of-artifice/polyglot-security-foundations/blob/e6ddcb907e770a6d68510799f014402e6eb851a4/agent-config.hcl#L25-L38)

## Why is this approach more secure than passing hardcoded tokens?

There are many reasons but here are a few.

### 1) Short Lifespan
The tokens used by the agent and the certificates it fetches are ephemeral. If they are leaked, they expire automatically in 24 hours. You can set this to whatever you want.

### 2) Decoupling
The application code does not contain any logic for talking to **Vault**. This makes the application code more self contained. Your dependencies become a lot simpler as you do not need specific drivers or libraries which is not the case with many cloud technologies.

### 3) Automatic Rotation
The **Vault Agent** automatically renews the certificate before it expires and overwrites the file in the shared volume. This allows for the potential for zero-downtime key rotation.

## How does the "Auto-Authorization" method work in the sandbox?

This project makes use of the `approle` autho-auth method.
1) The `setup_vault.sh` script write a `role_id` and `secret_id` to a specific folder on the host.
2) The **Vault Agent** container mounts this folder at `/app/secrets/`
3) When the system starts, the Agent reads the files to authenticate with Vault, obtains a token and begins managing the certificate lifecycle.

You can find out more about auto-authentication here: https://developer.hashicorp.com/vault/docs/agent-and-proxy/autoauth

## Resources

https://www.youtube.com/embed/sh2nwXJLDkE?si=M8kXxYB2g-xj8Lpx
