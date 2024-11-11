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

// Returns a Container built from the Dockerfile in the provided Directory
func (m *Ci) Build(ctx context.Context, directory *dagger.Directory) *dagger.Container {
	return dag.Container().Build(directory)
}

// Returns the result of haml-lint run against the sources in the provided Directory
func (m *Ci) Lint(ctx context.Context, directory *dagger.Directory) (string, error) {
    return dag.Container().
        From("ruby:latest").
        WithMountedDirectory("/mnt", directory).
        WithWorkdir("/mnt").
        WithExec([]string{"gem", "install", "haml-lint"}).
        WithExec([]string{"haml-lint", "--reporter", "json", "."}).
        Stdout(ctx)
}
