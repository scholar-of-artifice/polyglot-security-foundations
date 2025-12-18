package main

import (
	"reckless-sleuth/internal/config"
	"reckless-sleuth/internal/sleuth"
)

func main() {

	// load configuration
	cfg := config.Load()
	// initialize the service
	agent := sleuth.New(cfg)
	// run the logic
	agent.Run()
}
