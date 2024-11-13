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
	// the built image
	Image *dagger.Container
}

// Returns a Container built from the Dockerfile in the provided Directory
func (m *Ci) Build(_ context.Context, dir *dagger.Directory) *dagger.Container {
	return dag.Container().Build(dir)
}

// Returns the result of haml-lint run against the sources in the provided Directory
func (m *Ci) Lint(dir *dagger.Directory) *dagger.File {
	return dag.Container().
		From("ruby:latest").
		WithMountedDirectory("/mnt", dir).
		WithWorkdir("/mnt").
		WithExec([]string{"gem", "install", "haml-lint"}).
		WithExec([]string{"sh", "-c", "haml-lint -r json . > lint.json || true"}).
		File("lint.json")
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

// Executes the test suite for the Rails application in the provided Directory
func (m *Ci) Test(ctx context.Context, dir *dagger.Directory) *dagger.Container {

	return dag.Container().
		From("registry.puzzle.ch/docker.io/ruby:3.2").
		WithExec([]string{"useradd", "-m", "-u", "1001", "ruby"}).
		WithServiceBinding("postgresql", m.Postgres(ctx, "11")).
		WithServiceBinding("memcached", m.Memcached(ctx, "latest")).
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
		WithExec([]string{"apt-get", "update"}).
		WithExec([]string{"apt-get", "-yqq", "install", "libpq-dev", "libvips-dev", "chromium", "graphviz", "imagemagick"}).
		WithUser("ruby").
		WithExec([]string{"gem", "update", "--system"}). // update bundler version
		WithExec([]string{"gem", "install", "bundler", "--version", `~>2`}).
		WithExec([]string{"bundle", "install", "--jobs", "4", "--retry", "3"}).
		WithExec([]string{"bundle", "exec", "rails", "db:create"}).
		WithExec([]string{"bundle", "exec", "rails", "db:migrate"}).
		WithExec([]string{"bundle", "exec", "rails", "assets:precompile"}).
		Terminal().
		WithExec([]string{"bundle", "exec", "rails", "test", "test/controllers", "test/domain", "test/fabricators", "test/fixtures", "test/helpers", "test/mailers", "test/models", "test/presenters", "test/support", "test/tarantula"})
}

// Creates an SBOM for the container
func (m *Ci) Sbom(container *dagger.Container) *dagger.File {
	trivy_container := dag.Container().
		From("aquasec/trivy").
		WithEnvVariable("TRIVY_JAVA_DB_REPOSITORY", "public.ecr.aws/aquasecurity/trivy-java-db")

	trivy := dag.Trivy(dagger.TrivyOpts{
		Container:          trivy_container,
		DatabaseRepository: "public.ecr.aws/aquasecurity/trivy-db",
	})

	sbom := trivy.Container(container).
		Report("cyclonedx").
		WithName("cyclonedx.json")

	return sbom
}

// Builds the container and creates an SBOM for it
func (m *Ci) SbomBuild(ctx context.Context, dir *dagger.Directory) *dagger.File {
	container := m.Build(ctx, dir)

	return m.Sbom(container)
}

// Scans the SBOM for vulnerabilities
func (m *Ci) Vulnscan(sbom *dagger.File) *dagger.File {
	trivy_container := dag.Container().
		From("aquasec/trivy").
		WithEnvVariable("TRIVY_JAVA_DB_REPOSITORY", "public.ecr.aws/aquasecurity/trivy-java-db")

	trivy := dag.Trivy(dagger.TrivyOpts{
		Container:          trivy_container,
		DatabaseRepository: "public.ecr.aws/aquasecurity/trivy-db",
	})

	return trivy.Sbom(sbom).Report("json")
}

// Executes all the steps and returns a Results object
func (m *Ci) Ci(ctx context.Context, dir *dagger.Directory) *Results {
	lintOutput := m.Lint(dir)
	securityScan := m.Sast(dir)
	image := m.Build(ctx, dir)
	sbom := m.Sbom(image)
	vulnerabilityScan := m.Vulnscan(sbom)

	return &Results{
		LintOutput:        lintOutput,
		SecurityScan:      securityScan,
		VulnerabilityScan: vulnerabilityScan,
		Image:             image,
	}
}

// Executes all the steps and returns a Results object
func (m *Ci) CiIntegration(ctx context.Context, dir *dagger.Directory) *Results {
	var wg sync.WaitGroup
	wg.Add(4)

	var lintOutput = func() *dagger.File {
		defer wg.Done()
		return m.Lint(dir)
	}()

	var securityScan = func() *dagger.File {
		defer wg.Done()
		return m.Sast(dir)
	}()

	var vulnerabilityScan = func() *dagger.File {
		defer wg.Done()
		return m.Vulnscan(m.Sbom(m.Build(ctx, dir)))
	}()

	var image = func() *dagger.Container {
		defer wg.Done()
		return m.Build(ctx, dir)
	}()

	// This Blocks the execution until its counter become 0
	wg.Wait()

	return &Results{
		LintOutput:        lintOutput,
		SecurityScan:      securityScan,
		VulnerabilityScan: vulnerabilityScan,
		Image:             image,
	}
}
