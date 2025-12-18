# use the official go image matching the go.mod version
FROM golang:1.24-alpine AS builder
WORKDIR /app
# copy the module files
COPY go.mod ./
RUN go mod download
# copy the source code
COPY . .
# compile the binary
RUN CGO_ENABLED=0 GOOS=linux go build -o reckless-sleuth ./cmd/eckless-sleuth
# runtime stuff
FROM alpine:latest
WORKDIR /app
# copy the compiled binary
COPY --from=builder /app/reckless-sleuth .
# run the binary directly
CMD ["./reckless-sleuth"]

