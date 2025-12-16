package main

import (
	"fmt"
	"log"
	"overwhelming-minotaur/internal/config"
	"overwhelming-minotaur/internal/server"
)

func main() {
	// load the configuration
	cfg := config.Load()
	// initialize the server
	srv := server.New(cfg)
	fmt.Printf("Complete: Server is listening on port %s\n", srv.Addr)

	// since we already provided the certs in TLSConfig, we pass empty strings
	if err := srv.ListenAndServeTLS("", ""); err != nil {
		log.Fatalf("Could not start server: %v", err)
	}

}
