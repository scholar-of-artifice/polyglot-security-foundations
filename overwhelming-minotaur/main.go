package main

import (
	"crypto/tls"
	"crypto/x509"
	"fmt"
	"io"
	"log"
	"net/http"
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

	// read the public certificate and the private key as a pair
	cert, err := tls.LoadX509KeyPair("certs/overwhelming-minotaur.crt", "certs/overwhelming-minotaur.key")
	if err != nil {
		log.Fatalf("Error loading certificate keypair: %v", err)
	}
	fmt.Println("Complete: Identity Keypair loaded.")
	// suppress unused variable error for now...
	_ = cert

	// configure TLS parameters
	tlsConfig := &tls.Config{
		Certificates: []tls.Certificate{cert},
		ClientCAs:    caCertPool,
		ClientAuth:   tls.RequireAndVerifyClientCert, // <- this enforces mutual TLS
	}
	fmt.Println("Complete: TLS parameters configured. (mTLS enforced)")

	// define the request handler

	// verify the incoming message and respond with the text defined in the project architecture
	handler := func(w http.ResponseWriter, r *http.Request) {
		// read the body of the request
		body, err := io.ReadAll(r.Body)
		if err != nil {
			http.Error(w, "Unable to read body", http.StatusBadRequest)
		}
		defer r.Body.Close()

		fmt.Printf("Received message: %s\n", string(body))
		// send the response
		response := "I really think secret messages are silly *chuckle*"
		w.Write([]byte(response))
		fmt.Printf("Sent response: %s\n", response)
	}

	// define the server, bind and listen
	server := &http.Server{
		Addr:      ":9000", // listen on port 9000
		Handler:   http.HandlerFunc(handler),
		TLSConfig: tlsConfig, // apply the mTLS settings
	}
	fmt.Printf("Complete: Server is listening on port %s", server.Addr)
	// since we already provided the certs in TLSConfig, we pass empty strings
	log.Fatal(server.ListenAndServeTLS("", ""))
}
