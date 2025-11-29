package app

import (
	"github.com/gorilla/mux"
)

type Register struct {
	apps []App
}

func NewRegister() *Register {
	return &Register{
		apps: []App{},
	}
}

func (r *Register) Add(app App) {
	r.apps = append(r.apps, app)
}

func (r *Register) Register(router *mux.Router) {
	for _, app := range r.apps {
		app.RegisterRoutes(router)
	}
}
