package main

import (
	"crypto/tls"
	"fmt"
	"log"
	"overwhelming-minotaur/internal/config"
	"overwhelming-minotaur/internal/server"
	"time"
)

func main() {
	// load the configuration
	cfg := config.Load()

	// wait for sidecar Vault agent
	fmt.Printf("Checking for certificate at %s\n", cfg.CertFile)
	for {
		if _, err := tls.LoadX509KeyPair(cfg.CertFile, cfg.KeyFile); err == nil {
			fmt.Println("Certificate found and valid! Starting server...")
			break
		}
		fmt.Println("Waiting for valid certficate...")
		time.Sleep(1 * time.Second)
	}

	// initialize the server
	srv := server.New(cfg)
	fmt.Printf("Complete: Server is listening on port %s\n", srv.Addr)

	// since we already provided the certs in TLSConfig, we pass empty strings
	if err := srv.ListenAndServeTLS("", ""); err != nil {
		log.Fatalf("Could not start server: %v", err)
	}

}
