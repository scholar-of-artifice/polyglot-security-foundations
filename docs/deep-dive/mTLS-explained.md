# 🔐 What is mTLS?

> *Distrust and caution are the parents of security. -Benjamin Franklin*

`mTLS` (Mutual Transport Layer Security) is a protocol that ensures two-way authentication between a client and a server. Unlike standard `TLS` (one-way TLS), where only the server verifies its identity to the client, `mTLS` requires both the client and the server to present and validate cryptographic certificates during the connection handshake.

## Key Concepts
`mTLS` is essential for securing `API` gateways, service-to-service communication in microservices architectures (e.g., service mesh), and sensitive internal systems where strong identity verification is critical.

### Two-Way Authentication
Both parties must verify the other's identity using their respective Public Key Infrastructure (`PKI`) certificates.

### Trust Establishment
A secure connection is only established after both parties confirm the validity of the other's certificate, typically against a trusted Certificate Authority (`CA`).

### Enhanced Security
By requiring the client to prove its identity, `mTLS` significantly improves security, preventing unauthorized access even if standard credential-based authentication (like usernames/passwords) is compromised or bypassed.

## Resources

https://developer.mozilla.org/en-US/docs/Web/Security/Defenses/Transport_Layer_Security

https://wiki.mozilla.org/Security/Server_Side_TLS

https://www.youtube.com/embed/b38k2GiLDdc?si=m_38AH1JBhTAT5BH

https://www.youtube.com/embed/uWmZZyaHFEY?si=m6z0l9WXEHYg_9CB