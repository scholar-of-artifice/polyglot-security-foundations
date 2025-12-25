# Zero Downtime Rotation Mechanics

> *You win battles by knowing the enemy's timing, and using a timing which the enemy does not expect. -Miyamoto Musashi*

In this article, you will learn why keys are rotated and how we automated this process in this application. You will also see how the `Hot Reload` mechanics work in the various services written in Go and Python.

## The Engineering Challenge

When writing distributed systems, you have a fundamental struggle between `permanence` and `security`. In short, nothing is *secure* forever. Given enough time, someone can crack your encryption or find vulnerabilities. Therefore, it is common policy that TLS certificates are temporary. They might last anywhere from 10 years to less than 90 days.

By forcing data to be current, we can better support zero-trust models by making it harder for attackers to exploit long-lived vulnerabilities. Shorter certificate lifespans limit the window for tinkering and misuse if a private key leaks while allowing for stronger cryptographic standards as they get invented and adopted.

### Container Restarts

In a traditional `static` infrastructure, updating a certificate often means scheduling a maintenance window to restart a service. In modern **Zero Trust** environments, certificate lifespans might be even less (1-24 hours). Relying on container restarts is architecturally flawed for several reasons:

#### Severed Connection

The most obvious issue is that a restart of services will kill all active connections. If you imagine a large file transfer, this is a hard failure.

You can imagine how inconvenient this is in the modern world where applications may be serving requests from all over the world all the time. Given enough users, a restart is inconvenient for a non-trivial number of people.

#### Availability Gap

Even highly optimized, light weight containers take non-zero time to initialize. Some image has to be downloaded, read from storage, initialized, and some IO is partitioned. During this time, the service is not available and is effectively down.

If you scale this to hundreds of component services, databases, caches, load balancers, and other infrastructure then the cumulative availability drop becomes significant.

#### An Overwhelming Stampede

Also, if certificate issuance is synchronized... a restart based strategy would force your entire fleet of deployed applications to reboot at the same time.

This causes a massive spike in usage across your cluster of machines and overwhelm upstream dependencies. Possibly you can effectively DDOS yourself.

### How can we address short credential lifespans without container restarts?

In short, we must create a `hot reload` mechanism as seen in [reloader.go](../../overwhelming-minotaur/internal/server/reloader.go). This essentially decouples the `identity lifecycle` from the `process lifecycle`. The application continues to serve existing connections using the old (valid) context while seamlessly switching to the new credentials for new incoming requests.

### Trade-off: Complexity vs Stability

The trade-off is increased code complexity. Instead of leaving it to the orchestrator to manage the lifecycle, the application must be `aware` of its own configuration state. Therefore, the engineer must actually write code which inspects the certificate file(s) instead of setting parameters in a config file. This introduces risks around contention for data on the file system. The writing below will explain how this is managed.

As a team or organization this requires contributors to have an advanced understanding of a given implementation language (concurrency primitives, run time behaviour, etc.).

## Go Implementation: Hooking the TLS Handshake

The following section describes the relevant parts of code in [`overwhelming-minotaur`](../../overwhelming-minotaur/).

In Go, the `http.ListenAndServeTLS` function is provided in the standard library. It loads certificates once (typically on startup). To achieve dynamic rotation, the author must drop down a layer into the `crypto/tls` package.

The documentation on the Go website often has parameters and types which mention `or else set GetCertificate.`.
[documentation - crypto/tls](https://pkg.go.dev/crypto/tls)

### What is `GetCertificate`?
`GetCertificate` is a field in some components of the API in the `crypto/tls` module. Instead of providing static certificate bytes, the user is to provide a function which will be called.

Here is where you can see it in this project. [See the code here](https://github.com/scholar-of-artifice/polyglot-security-foundations/blob/24d1f3513eab0e6e8244517793f0fdd33ec65669/overwhelming-minotaur/internal/server/server.go#L37-L41)

Every time a new client attempts a TLS handshake, the Go runtime hits this function. This gives us a just-in-time opportunity to check if the credentials have rotated. 

## What is `reloader`?

`GetCertificate` is attached to the custom type, `reloader`.
```go
...
    reloader.GetCertificate
...
```
Here is a link to the definition of the type: [reloader.go](../../overwhelming-minotaur/internal/server/reloader.go)

### How `CertReloader` works
`CertReloader` is a struct which allows us to hold **credentials**. It also holds the **time stamp** to know the time when a credential was last modified.

`GetCertificate` is part of the public API for this type. If a change is detected, the function reloads the new X509 key-pair. We have to code to the interface provided in the `crypto/tls` documentation:

```go
GetCertificate func(*ClientHelloInfo) (*Certificate, error)
```

### Handling file reads safely

As an engineer, we give up  assumptions about our programs when reaching out to the file system. Remember, the `Vault Agent` will periodically get new credentials from the `Vault` service and overwrite the old file.

We do not want to be reading credentials while the agent is mid-write. Therefore, we must tell the Operating System that we want to take a Mutex. 

This establishes a guard for thread-safe access of the file.

## Python Implementation: Dynamic SSL Contexts

The following section describes the relevant parts of code in [`siege-leviathan`](../../siege-leviathan/).

While Go allows us to hook into the handshake via `GetCertificate`, Python's `ssl` library works slightly differently. When acting as a client, we typically create an `ssl.SSLContext` once and reuse it for connection pooling.

However, if we need to support credential rotation, we cannot instantiate the context only at startup. There needs to be a mechanism that checks the freshness of certificates before every new connection attempt.

### `MTLSContextManager`

The standard logic has been wrapped in a custom type called `MTLSContextManager`. The implementation is here: [`MTLSContextManager.py`](../../siege-leviathan/app/core/MTLSContextManager.py).

Instead of relying on the web framework to handle SSL, there needs to be an explicit management of the context lifecylce.
The `MTLSContextManager` wraps the loading logic in a `try... except` block catching `ssl.SSLError` and `OSError`.
If a partial write is detected, it catches the exception, logs a warning, and falls back to the existing `ssl_context`.
This means the service does not crash during rotation.

### What Happens to in-flight requests?

The system swaps the configuration structs in memory (`overwhelming-minotaur`) or the `SSLContext` object (`siege-leviathan`).
Therefore, existing connections continue to use the *old* object until they close.
Only *new* connections initiated after the swap will use the new certificate.
This allows connections to not be dropped.
Of course, given some modification you can force connections to drop.

### Graceful Degradation

If the **Vault Agent** fails to renew the certificate, the application continues to use the old credential.
This provides a buffer period for someone to fix the infrastructure.
However, you only have the remaining TTL of the cert to do this.
