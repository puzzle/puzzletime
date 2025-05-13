// A generated module for Implementation functions
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
	"dagger/implementation/internal/dagger"
	"fmt"
)

type Implementation struct{}

// Returns a directory containing the lint results
func (m *Implementation) Lint(
	dir *dagger.Directory,
	// +optional
	// +default=false
	pass bool,
) *dagger.Directory {
	return dag.Container().
		From("ruby:latest").
		WithMountedDirectory("/mnt", dir).
		WithWorkdir("/mnt").
		WithExec([]string{"gem", "install", "haml-lint"}).
		WithExec([]string{"sh", "-c", "mkdir -p /mnt/lint"}).
		WithExec(m.lintCommand(pass)).
		Directory("/mnt/lint")
}

// Returns the lint command
func (m *Implementation) lintCommand(pass bool) []string {
	if pass {
		return []string{"sh", "-c", "haml-lint -r json . > lint/lint.json || true"}
	}
	return []string{"sh", "-c", "haml-lint -r json . > lint/lint.json"}
}

func (m *Implementation) Test(
	dir *dagger.Directory,
) *dagger.Directory {
	return m.BaseTestContainer(dir).
		WithServiceBinding("postgresql", m.Postgres("11")).
		WithServiceBinding("memcached", m.Memcached("latest")).
		WithExec([]string{"bundle", "exec", "rails", "db:create"}).
		WithExec([]string{"bundle", "exec", "rails", "db:migrate"}).
		WithExec([]string{"bundle", "exec", "rails", "assets:precompile"}).
		WithExec([]string{"sh", "-c", "bundle exec rails test test/controllers test/domain test/fabricators test/fixtures test/helpers test/mailers test/models test/presenters test/support test/tarantula"}).
		Directory("/mnt/test/reports")
}

func (m *Implementation) IntegrationTest(
	dir *dagger.Directory,
) *dagger.Directory {
	return m.BaseTestContainer(dir).
		WithServiceBinding("postgresql", m.Postgres("11")).
		WithServiceBinding("memcached", m.Memcached("latest")).
		WithExec([]string{"bundle", "exec", "rails", "db:create"}).
		WithExec([]string{"bundle", "exec", "rails", "db:migrate"}).
		WithExec([]string{"bundle", "exec", "rails", "assets:precompile"}).
		WithExec([]string{"sh", "-c", "bundle exec rails test test/integration"}).
		Directory("/mnt/test/reports")
}

// Returns a Container with the base setup for running the rails test suite
func (m *Implementation) BaseTestContainer(
	dir *dagger.Directory,
) *dagger.Container {
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

// Returns security scan results
func (m *Implementation) SecurityScan(dir *dagger.Directory) *dagger.Directory {
	return dag.Container().
		From("presidentbeef/brakeman:latest").
		WithMountedDirectory("/app", dir).
		WithWorkdir("/app").
		WithExec([]string{"sh", "-c", "mkdir -p /app/sast"}).
		WithExec([]string{"sh", "-c", "/usr/src/app/bin/brakeman -o /app/sast/brakeman-output.tabs"}).
		Directory("/app/sast")
}

// Creates a PostgreSQL service for local testing based on the official image with the provided version. If no version is provided, 'latest' will be used.
func (m *Implementation) Postgres(
	// +optional
	// +default="latest"
	version string,
) *dagger.Service {
	return dag.Container().
		From(fmt.Sprintf("postgres:%s", version)).
		WithEnvVariable("POSTGRES_PASSWORD", "postgres").
		WithExposedPort(5432).
		AsService()
}

// Creates a memcached service for local testing based on the official image with the provided version. If no version is provided, 'latest' will be used.
func (m *Implementation) Memcached(
	// +optional
	// +default="latest"
	version string,
) *dagger.Service {
	return dag.Container().
		From(fmt.Sprintf("memcached:%s", version)).
		WithExposedPort(11211).
		AsService()
}
