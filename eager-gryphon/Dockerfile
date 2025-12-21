# --- builder stage ---
FROM ocaml/opam:ubuntu-25.04-ocaml-5.5 as builder
# establish the user
USER root
# install system dependencies required for async_ssl
RUN apt-get update && apt-get install -y \
    libssl-dev \
    pkg-config \
    libgmp-dev \
    libgsl-dev \
    && rm -rf /var/lib/apt/lists/*
# change user to opam
USER opam
# set working directory
WORKDIR /home/opam/app
# copy the dune-project and opam file to cache dependencies
COPY --chown=opam:opam dune-project eager_gryphon.opam* ./
# install OCaml dependencies
RUN opam install . --deps-only --with-test
# copy the rest of the source code
COPY --chown=opam:opam . .
# build the binary
RUN opam exec -- dune build @install --profile release
# --- runtime stage ---
FROM ubuntu:25.04
WORKDIR /app
RUN apt-get update && apt-get install -y \
    libssl3 \
    libgmp10 \
    libgsl27 \
    && rm -rf /var/lib/apt/lists/*
# copy the compiled binary from the builder stage
COPY --from=builder /home/opam/app/_build/default/bin/main.exe /app/eager-gryphon
# create the certs directory for the sidecar volume
RUN mkdir certs
# replace installing ca-certicicates with just creating the empty directory...libssl might require it
RUN mkdir -p /etc/ssl/certs
# run the binary
CMD ["./eager-gryphon"]