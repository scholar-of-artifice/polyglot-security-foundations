package sleuth

import (
	"crypto/tls"
	"fmt"
	"net/http"
	"reckless-sleuth/internal/config"
	"time"
)

type Sleuth struct {
	cfg    *config.Config
	client *http.Client
}

func New(cfg *config.Config) *Sleuth {
	// configure a client that skips verifying the server's CA
	tr := &http.Transport{
		TLSClientConfig: &tls.Config{
			InsecureSkipVerify: true,
		},
	}
	return &Sleuth{
		cfg: cfg,
		client: &http.Client{
			Transport: tr,
			Timeout:   2 * time.Second,
		},
	}
}

func (s *Sleuth) Run() {
	fmt.Println("Starting test run...")
	// enter the "simulation loop"
	for i := 1; i <= s.cfg.MaxAttempts; i++ {
		fmt.Printf("[%d/%d]Attempting to access %s without a certificate...\n", i, s.cfg.MaxAttempts, s.cfg.TargetURL)
		resp, err := s.client.Get(s.cfg.TargetURL)
		if err != nil {
			// this is the correct path
			fmt.Printf("connection rejected: %v\n", err)
		} else {
			// this path is when the lock is broken...
			fmt.Printf("CRITICAL FAILURE: connection accepted %s\n", resp.Status)
			resp.Body.Close()
		}
		if i < s.cfg.MaxAttempts {
			// wait before trying again
			time.Sleep(5 * time.Second)
		}
	}
	fmt.Println("Test run complete.")
}
