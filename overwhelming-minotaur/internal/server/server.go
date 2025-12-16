package server

import (
	"crypto/tls"
	"crypto/x509"
	"fmt"
	"log"
	"net/http"
	"os"
	"overwhelming-minotaur/internal/config"
	"overwhelming-minotaur/internal/handlers"
)

func New(cfg *config.Config) *http.Server {
	// read the Root CA certificate file from the disk
	caCertFile, err := os.ReadFile(cfg.CertFile)
	if err != nil {
		log.Fatalf("Error reading CA certificate from %s: %v", cfg.CertFile, err)
	}

	// create a new certificate pool
	caCertPool := x509.NewCertPool() // think of this like a trusted contact list
	// add our Root CA to the pool
	ok := caCertPool.AppendCertsFromPEM(caCertFile)
	if !ok {
		log.Fatalf("Failed to append CA certifcate to pool. Is the file a valid PEM?")
	}
	fmt.Println("Complete: Root CA loaded and trusted.")

	// read the public certificate and the private key as a pair
	cert, err := tls.LoadX509KeyPair(cfg.CertFile, cfg.KeyFile)
	if err != nil {
		log.Fatalf("Error loading certificate keypair: %v", err)
	}
	fmt.Println("Complete: Identity Keypair loaded.")

	// configure TLS parameters
	tlsConfig := &tls.Config{
		Certificates: []tls.Certificate{cert},
		ClientCAs:    caCertPool,
		ClientAuth:   tls.RequireAndVerifyClientCert, // <- this enforces mutual TLS
		MinVersion:   tls.VersionTLS12,
	}
	fmt.Println("Complete: TLS parameters configured. (mTLS enforced)")

	// create the server struct
	return &http.Server{
		Addr:      ":" + cfg.Port,
		Handler:   http.HandlerFunc(handlers.SecretMessageHandler),
		TLSConfig: tlsConfig,
	}
}
