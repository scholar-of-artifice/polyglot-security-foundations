package config

import (
	"fmt"
	"os"
	"strconv"
)

type Config struct {
	TargetURL   string
	MaxAttempts int
}

func Load() *Config {
	// get the target from the environment
	target := os.Getenv("TARGET_URL")
	if target == "" {
		fmt.Println("Warning: TARGET_URL not set. defaulting to localhost...")
		target = "https://localhost:9090"
	}
	// allow configuring the duration via env variable, default to 30
	attemptsStr := os.Getenv("MAX_ATTEMPTS")
	attempts, err := strconv.Atoi(attemptsStr)
	if err != nil || attempts <= 0 {
		attempts = 30
	}
	// return the configuration
	return &Config{
		TargetURL:   target,
		MaxAttempts: attempts,
	}
}
