# Quick Start Guide

In this article, you will find the directions for getting this application up and running.
I wrote this as a seperate article so that it is easier on the eyes.

## Directions

### 0) Get `Docker`!
Go download docker desktop from https://www.docker.com

#### Explanation
`Docker` and `docker-compose` are both required to run this project.

### 1) Get the code!

```
git clone https://github.com/scholar-of-artifice/polyglot-security-foundations.git
```

### Explanation
You need to download this repository. Of course you can download the repo as a .zip file or use GitHub desktop.

### 2) Set up the `.env` file
Rename `.env.example` to `.env`.

#### Explanation
When you download this repository, you will see a `.env.example` file.
The docker related files need the variables in here.

### 3) Run the System

Open this project directory in your terminal instance.
Run the following command:
```bash
docker compose up --build
```

#### Explanation
This will tell `docker` to look for the `docker-compose` file and build the project.
It will likely pull several image from docker hub including `hashicorp/vault`.

### What to Observe
- Success: `siege-leviathan` logs `overwhelming_minotaur_responds: ...`
    - Handshake success
- Rejection: `reckless-sleuth` logs `connections rejected: remote error: tls: bad certificate
    - Security boundary intact