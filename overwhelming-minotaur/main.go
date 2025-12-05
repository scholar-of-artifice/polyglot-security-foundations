package main

import (
	"crypto/x509"
	"fmt"
	"log"
	"os"
)

func main() {
	fmt.Println("service: overwhelming-minotaur starting...")
	// read the Root CA certificate file from the disk
	caCertFile, err := os.ReadFile("certs/ca.crt")
	if err != nil {
		log.Fatalf("Error reading CA certificate: %v", err)
	}
	// create a new certificate pool
	caCertPool := x509.NewCertPool() // think of this like a trusted contact list
	// add our Root CA to the pool
	ok := caCertPool.AppendCertsFromPEM(caCertFile)
	if !ok {
		log.Fatalf("Failed to append CA certifcate to pool. Is the file a valid PEM?")
	}
	fmt.Println("Complete: Root CA loaded and trusted.")
}
