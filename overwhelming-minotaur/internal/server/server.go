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
	// initialize a certificate reloader with the paths from the config
	reloader := &CertReloader{
		certFile: cfg.CertFile,
		keyFile:  cfg.KeyFile,
	}
	// perform an initial load to ensure the certificate is valid before use
	if err := reloader.maybeReload(); err != nil {
		log.Fatalf("Error loading initial certificate keypair: %v", err)
	}
	fmt.Println("Complete: Identity Keypair loaded.")

	// configure TLS parameters
	tlsConfig := &tls.Config{
		GetCertificate: reloader.GetCertificate, // <- use GetCertificate hook
		ClientCAs:      caCertPool,
		ClientAuth:     tls.RequireAndVerifyClientCert, // <- this enforces mutual TLS
		MinVersion:     tls.VersionTLS12,
	}
	fmt.Println("Complete: TLS parameters configured. (mTLS enforced)")

	// create the server struct
	return &http.Server{
		Addr:      ":" + cfg.Port,
		Handler:   http.HandlerFunc(handlers.SecretMessageHandler),
		TLSConfig: tlsConfig,
	}
}
