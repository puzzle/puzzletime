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
	"fmt"
	"sync"
)

type Ci struct{}

type Results struct {
	// haml-lint output as json
	LintOutput *dagger.File
	// brakeman output as plain text
	SecurityScan *dagger.File
	// trivy results as json
	VulnerabilityScan *dagger.File
	// the SBOM
	Sbom *dagger.File
	// the built image
	Image *dagger.Container
	// the test reports
	TestReports *dagger.Directory
}

// Returns a lint container
func (m *Ci) BuildLintContainer(dir *dagger.Directory) *dagger.Container {
	return dag.Container().
		From("ruby:latest").
		WithMountedDirectory("/mnt", dir).
		WithWorkdir("/mnt").
		WithExec([]string{"gem", "install", "haml-lint"})
}

// Returns the lint command
func (m *Ci) lintCommand(pass bool) []string {
	if (pass) {
		return []string{"sh", "-c", "haml-lint -r json . > lint.json || true"}
	}
	return []string{"sh", "-c", "haml-lint -r json . > lint.json"}
}

// Returns the test command
func (m *Ci) testCommand() []string {
	return []string{"sh", "-c", "bundle exec rails test -v test/controllers test/domain test/fabricators test/fixtures test/helpers test/mailers test/models test/presenters test/support test/tarantula"}
}

// Returns the Sast report as a file
func (m *Ci) Sast(dir *dagger.Directory) *dagger.File {
	return dag.Container().
		From("presidentbeef/brakeman:latest").
		WithMountedDirectory("/app", dir).
		WithWorkdir("/app").
		WithExec([]string{"/usr/src/app/bin/brakeman"}).
		File("/app/brakeman-output.tabs")
}

// Creates a PostgreSQL service for local testing based on the official image with the provided version. If no version is provided, 'latest' will be used.
func (m *Ci) Postgres(
	_ context.Context,
	// +optional
	// +default="latest"
	version string) *dagger.Service {

	return dag.Container().
		From(fmt.Sprintf("postgres:%s", version)).
		WithEnvVariable("POSTGRES_PASSWORD", "postgres").
		WithExposedPort(5432).
		AsService()
}

// Creates a memcached service for local testing based on the official image with the provided version. If no version is provided, 'latest' will be used.
func (m *Ci) Memcached(
	_ context.Context,
	// +optional
	// +default="latest"
	version string) *dagger.Service {

	return dag.Container().
		From(fmt.Sprintf("memcached:%s", version)).
		WithExposedPort(11211).
		AsService()
}


// Returns a test container
func (m *Ci) BuildTestContainer(ctx context.Context, dir *dagger.Directory) *dagger.Container {
	return m.BaseTestContainer(ctx, dir).
		WithServiceBinding("postgresql", m.Postgres(ctx, "11")).
		WithServiceBinding("memcached", m.Memcached(ctx, "latest")).
		WithExec([]string{"bundle", "exec", "rails", "db:create"}).
		WithExec([]string{"bundle", "exec", "rails", "db:migrate"}).
		WithExec([]string{"bundle", "exec", "rails", "assets:precompile"})
}

// Returns a Container with the base setup for running the rails test suite
func (m *Ci) BaseTestContainer(_ context.Context, dir *dagger.Directory) *dagger.Container {
	return dag.Container().
		From("registry.puzzle.ch/docker.io/ruby:3.2").
		WithExec([]string{"useradd", "-m", "-u", "1001", "ruby"}).
		WithMountedDirectory("/mnt", dir, dagger.ContainerWithMountedDirectoryOpts{Owner: "ruby"}).
		WithWorkdir("/mnt").
		WithEnvVariable("RAILS_DB_HOST", "postgresql"). // This is the service name of the postgres container called by rails
		WithEnvVariable("RAILS_TEST_DB_HOST", "postgresql").
		WithEnvVariable("RAILS_TEST_DB_NAME", "postgres").
		WithEnvVariable("RAILS_TEST_DB_USERNAME", "postgres").
		WithEnvVariable("RAILS_TEST_DB_PASSWORD", "postgres").
		WithEnvVariable("RAILS_ENV", "test").
		WithEnvVariable("CI", "true").
		WithEnvVariable("PGDATESTYLE", "German").
		WithEnvVariable("TZ", "Europe/Zurich").
		WithEnvVariable("DEBIAN_FRONTEND", "noninteractive").
		WithEnvVariable("TEST_REPORTS", "true").
		WithExec([]string{"apt-get", "update"}).
		WithExec([]string{"apt-get", "-yqq", "install", "libpq-dev", "libvips-dev", "chromium", "graphviz", "imagemagick"}).
		WithUser("ruby").
		//WithExec([]string{"gem", "update", "--system"}).
		WithExec([]string{"gem", "install", "bundler", "--version", `~>2`}).
		WithExec([]string{"bundle", "install", "--jobs", "4", "--retry", "3"})
}

// Executes all the steps and returns a Results object
func (m *Ci) Ci(
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
) *Results {
	lintOutput := dag.GenericPipeline().Lint(m.BuildLintContainer(dir), m.lintCommand(pass), "lint.json")
	securityScan := m.Sast(dir)
	image := dag.GenericPipeline().Build(dir)
	sbom := dag.GenericPipeline().Sbom(image)
	vulnerabilityScan := dag.GenericPipeline().Vulnscan(sbom)
	testReports := dag.GenericPipeline().Test(m.BuildTestContainer(ctx, dir), testCommand, "/mnt/test/reports")
	digest, err := dag.GenericPipeline().Publish(ctx, image, registryAddress)

	if err == nil {
		dag.GenericPipeline().PublishToDeptrack(ctx, sbom, dtAddress, dtApiKey, dtProjectUUID)
		dag.GenericPipeline().Sign(ctx, registryUsername, registryPassword, digest)
		dag.GenericPipeline().Attest(ctx, registryUsername, registryPassword, digest, sbom, "cyclonedx")
	}

	return &Results{
		TestReports:       testReports,
		LintOutput:        lintOutput,
		SecurityScan:      securityScan,
		VulnerabilityScan: vulnerabilityScan,
		Sbom:              sbom,
		Image:             image,
	}
}

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
) (*dagger.Directory, error) {
	var wg sync.WaitGroup
	wg.Add(5)

	var lintOutput = func() *dagger.File {
		defer wg.Done()
		return dag.GenericPipeline().Lint(m.BuildLintContainer(dir), m.lintCommand(pass), "lint.json")
	}()

	var securityScan = func() *dagger.File {
		defer wg.Done()
		return m.Sast(dir)
	}()

	var vulnerabilityScan = func() *dagger.File {
		defer wg.Done()
		return dag.GenericPipeline().Vulnscan(dag.GenericPipeline().SbomBuild(dir))
	}()

	var image = func() *dagger.Container {
		defer wg.Done()
		return dag.GenericPipeline().Build(dir)
	}()

	var testReports = func() *dagger.Directory {
		defer wg.Done()
		return dag.GenericPipeline().Test(m.BuildTestContainer(ctx, dir), testCommand, "/mnt/test/reports")
	}()

	// This Blocks the execution until its counter become 0
	wg.Wait()

	// Get the names of the files to fail on errors of the functions
	lintOutputName, err := lintOutput.Name(ctx)
	if err != nil {
		return nil, err
	}
	securityScanName, err := securityScan.Name(ctx)
	if err != nil {
		return nil, err
	}
	vulnerabilityScanName, err := vulnerabilityScan.Name(ctx)
	if err != nil {
		return nil, err
	}

	// After linting, scanning and testing is done, we can create the sbom and publish the image
	wg.Add(2)

	var sbom = func() *dagger.File {
		defer wg.Done()
		return dag.GenericPipeline().Sbom(image)
	}()

	digest, err := func() (string, error) {
		defer wg.Done()
		return dag.GenericPipeline().Publish(ctx, image, registryAddress)
	}()

	// This Blocks the execution until its counter become 0
	wg.Wait()

	// After publishing the image, we can sign and attest
	if err != nil {
		return nil, err
	}

	dag.GenericPipeline().PublishToDeptrack(ctx, sbom, dtAddress, dtApiKey, dtProjectUUID)
	dag.GenericPipeline().Sign(ctx, registryUsername, registryPassword, digest)
	dag.GenericPipeline().Attest(ctx, registryUsername, registryPassword, digest, sbom, "cyclonedx")

	sbomName, _ := sbom.Name(ctx)
	result_container := dag.Container().
		WithWorkdir("/tmp/out").
		WithFile(fmt.Sprintf("/tmp/out/lint/%s", lintOutputName), lintOutput).
		WithFile(fmt.Sprintf("/tmp/out/scan/%s", securityScanName), securityScan).
		WithDirectory("/tmp/out/unit-tests/", testReports).
		WithFile(fmt.Sprintf("/tmp/out/vuln/%s", vulnerabilityScanName), vulnerabilityScan).
		WithFile(fmt.Sprintf("/tmp/out/sbom/%s", sbomName), sbom)
	return result_container.
		Directory("."), err
}
