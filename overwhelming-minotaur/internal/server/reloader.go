package server

import (
	"crypto/tls"
	"log"
	"os"
	"sync"
	"time"
)

// holds the state of the certificate and handles reloading
type CertReloader struct {
	certFile     string
	keyFile      string
	cachedCert   *tls.Certificate
	lastModified time.Time
	mu           sync.RWMutex
}

func (cr *CertReloader) maybeReload() error {
	// get the file stats to check the modification time
	info, err := os.Stat(cr.certFile)
	if err != nil {
		// if the file is missing or unreadable, return the error
		// in a real scenario you might want to log this
		return err
	}
	// check if the file is newer than the last load
	if !info.ModTime().After(cr.lastModified) && cr.cachedCert != nil {
		return nil
	}
	// load the new keypair
	// NOTE: do this before locking to minimize the time the mutex is held
	newCert, err := tls.LoadX509KeyPair(cr.certFile, cr.keyFile)
	if err != nil {
		return err
	}
	// lock for writing to update the struct
	cr.mu.Lock()
	defer cr.mu.Unlock()
	cr.cachedCert = &newCert
	cr.lastModified = info.ModTime()

	log.Printf("Certificate reloaded. Modifed at: %v", cr.lastModified)
	return nil
}

// satisfies the tls.Config.GetCertificate signature.
// it is called by the TLS handshake logic for every new connection
func (cr *CertReloader) GetCertificate(_ *tls.ClientHelloInfo) (*tls.Certificate, error) {
	// check if there is a need to reload from disk
	if err := cr.maybeReload(); err != nil {
		// if cannot reload, might still be able to use old certs
		// if there is none, then handshake should fail
		log.Printf("Failed to reload certificate: %v", err)
	}
	// safely read the cached cert
	cr.mu.RLock()
	defer cr.mu.RUnlock()
	if cr.cachedCert == nil {
		// this should only happen if the initial load failed and there is no backup
		return nil, os.ErrNotExist
	}
	return cr.cachedCert, nil
}
