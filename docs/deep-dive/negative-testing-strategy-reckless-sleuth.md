# Negative Testing Strategy [`reckless-sleuth`]

In this article you will learn about `reckless-sleuth`, the negative test which demonstrates the authentication mechanisms are working.

## What does `reckless-sleuth` do?

`reckless-sleuth` is a client application that attempts to connect **without** presenting a client certificate or a self-signed certificate. For this service, the TLS handshake fails and the connection is rejected.

`siege-leviathan` demonstrates that a connection is possible when there is a valid certificate signed by our simulated Certificate Authority. For this service, the TLS handshake is successful.


## At what layer of the OSI model is the connection rejected?

The connection is rejected at **Layer 5 (Session Layer)**, specifically during the TLS handshake.

The `overwhelming-minotaur` server is configured [here](https://github.com/scholar-of-artifice/polyglot-security-foundations/blob/63050a1294ffff00420898c751ffe2aa1e080c9d/overwhelming-minotaur/internal/server/server.go#L43)
This means that the Go runtime itself enforces the security requirement before the request is ever passed to the HTTP handler function.

### Identity vs. Location
Unlike a Firewall (Layer 3/4) which relies on IP addresses, layer 5 relies on cryptographic identity.
This allows the security mechanism to work in dynamic environments where IP addresses change all the time.

### Protection of Resources
The handshake fails before the application accepts the request. This means unauthorized traffic never consumes application resources and untrusted inputs are not processed.

## How does this confirm that our Zero-Trust boundary is actually enforcing rules?

The `reckless-sleuth` code explicitly skips verification of the server [(code here)](https://github.com/scholar-of-artifice/polyglot-security-foundations/blob/63050a1294ffff00420898c751ffe2aa1e080c9d/reckless-sleuth/internal/sleuth/sleuth.go#L20), meaning it is willing to talk to anyone.
**Do not ever do that in production.**

However, because the *server* demands a certificate that `reckless-sleuth` does not have, the handshake fails with a specific error. [code here](https://github.com/scholar-of-artifice/polyglot-security-foundations/blob/63050a1294ffff00420898c751ffe2aa1e080c9d/reckless-sleuth/internal/sleuth/sleuth.go#L40)

This proves that the security boundary is enforced by the infrastructure (the TLS config), not just by application logic checking a header.
