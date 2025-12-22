# Zero Downtime Rotation Mechanics

> *You win battles by knowing the enemy's timing, and using a timing which the enemy does not expect. -Miyamoto Musashi*

In this article, you will learn why keys are rotated and how we automated this process in this applicaiton. You will also see how the `Hot Reload` mechanics work in the various services written in Go and Python.

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

If you scale this to hundreds of component service, databases, chaches, load blancers, and other infrastructure then the cummulative availablity drop becomes significant.

#### An Overwhelming Stampede

Also, if certificate issuance is cynchronized... a restart based strategy would force your entire fleet of deployed applications to reboot at the same time.

This causes a massive spike in usage across your cluster of machines and overwhelm upstream dependencies. Possibly you can effectively DDOS yourself.

### How can we address short credential lifespans without container restarts?

In short, we must create a `hot reload` mechanism as seen in [reloader.go](../../overwhelming-minotaur/internal/server/reloader.go). This essentially decouples the `identity lifecycle` from the `process lifecycle`. The application continues to serve existing connections using the old (valid) context while seamlessly switching to the new credentials for new incoming requests.

### What is the trade-off of using `hot reload`?

There are 2 primary trade-offs of doing this.

<!--TODO-->

## Go Implementation: Hooking the TLS Handshake

<!--TODO-->

## Python Implementation: Dynamic SSL Contexts

<!--TODO-->

## Edge Cases & Safey

<!--TODO-->

### Handling File System Race Conditions

<!--TODO-->

### What Happens to in-flight requests?

<!--TODO-->

### Graceful Degredation

<!--TODO-->

## Verification

<!--TODO-->

### Simulating Credential Rotation

<!--TODO-->

### Log Analysis: Confirming the "Reload" Event

<!--TODO-->

<!--
## What happens when a certificate expires while a connection is active?
## How does the Go service work?
## What are the tradeoffs
-->