package main

import (
	"embed"
	"io/fs"
	"log"
	"net"
	"net/http"

	"github.com/gorilla/mux"

	"systray-app/app"
	"systray-app/cmd/apps"
)

//go:embed all:frontend
var webAssets embed.FS
var staticFilePath = "frontend/out"

const (
	AppTitle   = "My Next.js App"
	AppTooltip = "My Go + Next.js Tray App"
)

func main() {
	// Start HTTP server in a goroutine
	apiRegister := app.NewRegister()
	err := apps.AddApps(apiRegister)
	if err != nil {
		log.Fatalf("Failed to add apps: %v", err)
	}
	srv := startServer(apiRegister)

	// Platform-specific run loop (systray on darwin+cgo, signal wait elsewhere)
	runApp(srv)
}

func startServer(apiRegister *app.Register) *http.Server {
	// Embed and prepare static files
	staticFS, err := fs.Sub(webAssets, staticFilePath)
	if err != nil {
		log.Fatal(err)
	}
	fileServer := http.FileServer(http.FS(staticFS))

	// Create root router with Gorilla Mux
	r := mux.NewRouter()

	apiRouter := r.PathPrefix("/api").Subrouter()
	if apiRegister != nil {
		apiRegister.Register(apiRouter)
	}

	// Static files catch-all (after API subrouter for priority)
	r.PathPrefix("/").Handler(fileServer)

	srv := &http.Server{
		Addr:    ":8080", // Binds to all interfaces (0.0.0.0:8080)
		Handler: r,
	}

	go func() {
		if err := srv.ListenAndServe(); err != nil && err != http.ErrServerClosed {
			log.Fatalf("Server failed: %v", err)
		}
	}()

	// Detect local IP for network access logging
	localIP := getLocalIP()
	log.Printf("Server started on http://0.0.0.0:8080")
	log.Printf("Local access: http://localhost:8080")
	if localIP != "" {
		log.Printf("Network access (from other machines): http://%s:8080", localIP)
	} else {
		log.Printf("Could not detect local IP; ensure firewall allows port 8080")
	}

	return srv
}

// getLocalIP returns the non-loopback IPv4 address of the machine
func getLocalIP() string {
	addrs, err := net.InterfaceAddrs()
	if err != nil {
		return ""
	}
	for _, addr := range addrs {
		if ipnet, ok := addr.(*net.IPNet); ok && !ipnet.IP.IsLoopback() {
			if ipnet.IP.To4() != nil {
				return ipnet.IP.String()
			}
		}
	}
	return ""
}
