package apps

import (
	"systray-app/app"
	"systray-app/apps/healthcheck"
)

func AddApps(apiRegister *app.Register) error {
	// Register HealthCheck app
	healthCheckApp := healthcheck.NewHealthCheck()
	apiRegister.Add(healthCheckApp)

	// Additional apps can be registered here
	return nil
}
