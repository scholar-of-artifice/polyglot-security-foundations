# mTLS-example
This is an example of making 2 services which use mTLS to authenticate requests.

## 🔐 What is mTLS?

`mTLS` (Mutual Transport Layer Security) is a protocol that ensures two-way authentication between a client and a server. Unlike standard `TLS` (one-way TLS), where only the server verifies its identity to the client, `mTLS` requires both the client and the server to present and validate cryptographic certificates during the connection handshake.

### Key Concepts
`mTLS` is essential for securing `API` gateways, service-to-service communication in microservices architectures (e.g., service mesh), and sensitive internal systems where strong identity verification is critical.

#### Two-Way Authentication
Both parties must verify the other's identity using their respective Public Key Infrastructure (`PKI`) certificates.

#### Trust Establishment
A secure connection is only established after both parties confirm the validity of the other's certificate, typically against a trusted Certificate Authority (`CA`).

#### Enhanced Security
By requiring the client to prove its identity, `mTLS` significantly improves security, preventing unauthorized access even if standard credential-based authentication (like usernames/passwords) is compromised or bypassed.

## The Setup

Here is an image which shows the services in this application.

![Image of Project Setup](https://github.com/scholar-of-artifice/mTLS-example/blob/main/docs/assets/images/mTLS-example-image.png)

### What is going on?
Service `siege-leviathan` is a service written with `Python` `FastAPI`. Service `overwhelming-minotaur` is a service written with standard `Go`. Service `reckless-sleuth` is a service written with standard `Go`.

`siege-leviathan` and `overwhelming-minotaur` communicate via an encrypted connection with `mTLS`. `reckless-sleuth` cannot read the communication between `siege-leviathan` and `overwhelming-minotaur`.

## Resources

https://youtu.be/b38k2GiLDdc?si=OEbBRe6AxxLCOL3w

https://youtu.be/uWmZZyaHFEY?si=dqc0obIQRsAYaoSr
