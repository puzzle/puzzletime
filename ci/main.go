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
)

type Ci struct{}

// Returns a Container built from the Dockerfile in the provided Directory
func (m *Ci) Build(_ context.Context, dir *dagger.Directory) *dagger.Container {
	return dag.Container().Build(dir)
}

// Returns the result of haml-lint run against the sources in the provided Directory
func (m *Ci) Lint(ctx context.Context, dir *dagger.Directory) (string, error) {
	return dag.Container().
		From("ruby:latest").
		WithMountedDirectory("/mnt", dir).
		WithWorkdir("/mnt").
		WithExec([]string{"gem", "install", "haml-lint"}).
		WithExec([]string{"haml-lint", "--reporter", "json", "."}).
		Stdout(ctx)
}

// Returns the Sast report as a file
func (m *Ci) Sast(ctx context.Context, directory *dagger.Directory) *dagger.File {
    return dag.Container().
			From("presidentbeef/brakeman:latest").
			WithMountedDirectory("/app", directory).
			WithWorkdir("/app").
			WithExec([]string{"/usr/src/app/bin/brakeman", }).
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
		From(fmt.Sprintf("postgres:%s", version)).
		WithEnvVariable("POSTGRES_PASSWORD", "postgres").
		WithExposedPort(5432).
		AsService()
}

// Executes the test suite for the Rails application in the provided Directory
func (m *Ci) Test(ctx context.Context, dir *dagger.Directory) *dagger.Container {
	return m.Build(ctx, dir).From("ruby:latest").
		WithEnvVariable("RAILS_TEST_DB_NAME", "postgres").
		WithEnvVariable("RAILS_TEST_DB_USERNAME", "postgres").
		WithEnvVariable("RAILS_TEST_DB_PASSWORD", "postgres").
		WithEnvVariable("RAILS_ENV", "test").
		WithEnvVariable("CI", "true").
		WithEnvVariable("PGDATESTYLE", "German").
		WithExec([]string{"sudo", "apt-get", "-yqq", "update"}).
		WithExec([]string{"sudo", "apt-get", "-yqq", "install", "libpq-dev", "libvips-dev"}).
		WithExec([]string{"gem", "install", "bundler", "--version", "'~> 2'"}).
		WithExec([]string{"bundle", "install", "--jobs", "4", "--retry", "3"}).
		WithExec([]string{"bundle", "exec", "rails", "db:create"}).
		WithExec([]string{"bundle", "exec", "rails", "db:migrate"}).
		WithExec([]string{"bundle", "exec", "rails", "assets:precompile"}).
		WithExec([]string{"bundle", "exec", "rails", "test"})
}
