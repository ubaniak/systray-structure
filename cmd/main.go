package main

import (
	"context"
	"embed"
	"io/fs"
	"log"
	"net"
	"net/http"
	"time"

	"github.com/getlantern/systray"
	"github.com/gorilla/mux"
	"github.com/pkg/browser"

	"systray-app/app"
)

//go:embed all:webapp
var webAssets embed.FS

func main() {
	// Start HTTP server in a goroutine
	apiRegister := app.NewRegister()
	srv := startServer(apiRegister)

	// Start system tray
	systray.Run(func() {
		systray.SetTitle("My Next.js App")
		systray.SetTooltip("My Go + Next.js Tray App")

		mOpen := systray.AddMenuItem("Open UI", "Open the web interface")
		mQuit := systray.AddMenuItem("Quit", "Exit the app")

		for {
			select {
			case <-mOpen.ClickedCh:
				url := "http://localhost:8080"
				if err := browser.OpenURL(url); err != nil {
					log.Printf("Failed to open browser: %v", err)
				}
			case <-mQuit.ClickedCh:
				systray.Quit()
				return
			}
		}
	}, func() {
		// Cleanup: Shut down server gracefully
		ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
		defer cancel()
		if err := srv.Shutdown(ctx); err != nil {
			log.Printf("Server forced to shutdown: %v", err)
		}
	})
}

func startServer(apiRegister *app.Register) *http.Server {
	// Embed and prepare static files
	staticFS, err := fs.Sub(webAssets, "webapp/out")
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
