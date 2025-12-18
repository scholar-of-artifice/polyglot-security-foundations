package main

import (
	"crypto/tls"
	"fmt"
	"net/http"
	"os"
	"time"
)

func main() {
	// get the target from the environment
	targetURL := os.Getenv("TARGET_URL")
	if targetURL == "" {
		fmt.Println("Warning: TARGET_URL not set. defaulting to localhost...")
		targetURL = "https://localhost:9090"
	}
	fmt.Printf("recless-sleuth starting. Targeting: %s\n", targetURL)
	// configure a client that skips verifying the server's CA
	tr := &http.Transport{
		TLSClientConfig: &tls.Config{
			InsecureSkipVerify: true
		},
	}
	client := &http.Client{Transport: tr}
	// enter the "simulation loop"
	maxAttempts := 30
	for i := 1; i <= maxAttempts; i++ {
		fmt.Printf("[%d/%d]Attempting to access %s without a certificate...\n", i, maxAttempts, targetURL)
		resp, err := client.Get(targetURL)
		if err != nil {
			// this is the correct path
			fmt.Printf("connection rejected: %v\n", err)
		} else {
			// this path is when the lock is broken...
			fmt.Printf("CRITICAL FAILURE: connection accepted %s\n", resp.Status)
			resp.Body.Close()
		}
		if i < maxAttempts {
			// wait before trying again
			time.Sleep(5 * time.Second)
		}
	}
	fmt.Println("Test run complete.")
}
