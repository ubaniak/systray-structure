package app

import (
	"github.com/gorilla/mux"
)

type App interface {
	RegisterRoutes(router *mux.Router)
}
