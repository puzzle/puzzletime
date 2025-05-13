// A generated module for Ci functions
//
// This module has been generated via dagger init and serves as a reference to
// basic module structure as you get started with Dagger.
//
// Two functions have been pre-created. You can modify, delete, or add to them,
// as needed. They demonstrate usage of arguments and return types using simple
// echo and grep commands. The functions can be called from the dagger CLI or
// from one of the SDKs.
//
// The first line in this comment block is a short description line and the
// rest is a long description with more detail on the module's purpose or usage,
// if appropriate. All modules should have a short description.

package main

import (
	"context"
	"dagger/ci/internal/dagger"
)

type Ci struct{}

// Executes all the steps and returns a directory with the results
func (m *Ci) CiIntegration(
	ctx context.Context,
	// source directory
	dir *dagger.Directory,
	// registry username for publishing the contaner image
	registryUsername string,
	// registry password for publishing the container image
	registryPassword *dagger.Secret,
	// registry address registry/repository/image:tag
	registryAddress string,
	// deptrack address for publishing the SBOM https://deptrack.example.com/api/v1/bom
	dtAddress string,
	// deptrack project UUID
	dtProjectUUID string,
	// deptrack API key
	dtApiKey *dagger.Secret,
	// ignore linter failures
	// +optional
	// +default=false
	pass bool,
) *dagger.Directory {
	return dag.PitcFlow().Iflex(
		// source directory
		dir,
		dagger.PitcFlowIflexOpts{
			LintReports:     dag.PitcFlow().Lint(dir, pass, dag.Implementation().AsPitcFlowLinting()),
			SecurityReports: dag.PitcFlow().SecurityScan(dir, dag.Implementation().AsPitcFlowSecurityScanning()),
			TestReports:     dag.PitcFlow().Test(dir, dag.Implementation().AsPitcFlowTesting()),
			//IntegrationTestReports: dag.PitcFlow().IntegrationTest(dir, dag.Implementation().AsPitcFlowIntegrationTesting()),
			// registry username for publishing the container image
			RegistryUsername: registryUsername,
			// registry password for publishing the container image
			RegistryPassword: registryPassword,
			// registry address registry/repository/image:tag
			RegistryAddress: registryAddress,
			// deptrack address for publishing the SBOM https://deptrack.example.com/api/v1/bom
			DtAddress: dtAddress,
			// deptrack project UUID
			DtProjectUUID: dtProjectUUID,
			// deptrack API key
			DtAPIKey: dtApiKey},
	)
}

func (m *Ci) Verify(
	ctx context.Context,
	file *dagger.File,
) (string, error) {
	return dag.PitcFlow().Verify(ctx, file)
}
