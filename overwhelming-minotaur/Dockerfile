# --- base builder stage ----
# use the official go image matching the go.mod version
FROM golang:1.24-alpine AS builder
# set the working directory inside the container
WORKDIR /app
# copy the go.mod file
COPY go.mod ./
# download dependencies (if there is a go.sum you would copy it above and run this)
RUN go mod download
# copy the source code into the contianer
COPY main.go .
# compile the application
# # CGO_ENABLED -> creates a statically linked binary (no external C library dependencies)
# # GOOS -> ensures the build targets the correct OS of the container
RUN CGO_ENABLED=0 GOOS=linux go build -o overwhelming-minotaur main.go

# --- runtime ---
# use a minimal alpine linux image for the final container to keep it small-ish
FROM alpine:latest
# set the working directory for the running application
WORKDIR /app
# create the certs directory explicitly
RUN mkdir certs secrets

# copy only the compiled binary from the builder stage
COPY --from=builder /app/overwhelming-minotaur .
# copy the vault binary from the official image
COPY --from=hashicorp/vault:latest /bin/vault /bin/vault
# copy the startup script over
COPY startup.sh .
# make it executable
RUN chmod +x startup.sh

# document that the container listen on port 9000
EXPOSE 9000
# use a command that starts the agent and the app
CMD ["./startup.sh"]


