package config

import (
	"log"
	"os"
)

type Config struct {
	Port     string
	CertFile string
	KeyFile  string
}

// load reads environment variables and terminates the program if any are missing.
func Load() *Config {

	// read config from environment variables
	port := os.Getenv("PORT")
	certFile := os.Getenv("CERT_FILE")
	keyFile := os.Getenv("KEY_FILE")
	// strict validation logic
	if port == "" || certFile == "" || keyFile == "" {
		log.Fatal("Error: PORT, CERT_FILE, and KEY_FILE environment variables must be set.")
	}
	return &Config{
		Port:     port,
		CertFile: certFile,
		KeyFile:  keyFile,
	}
}
