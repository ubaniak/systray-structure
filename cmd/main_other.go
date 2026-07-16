//go:build !darwin && !linux

package main

import (
	"log"
	"net/http"
	"os"
	"os/signal"
	"syscall"
)

func runApp(srv *http.Server) {
	sigChan := make(chan os.Signal, 1)
	signal.Notify(sigChan, syscall.SIGINT, syscall.SIGTERM)
	<-sigChan
	log.Println("Shutdown signal received")
	if err := srv.Close(); err != nil {
		log.Printf("Server close error: %v", err)
	}
}
