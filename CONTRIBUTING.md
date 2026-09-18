# Contributing

We love pull requests from everyone:

Fork, then clone the repo:

    git clone git@github.com:your-username/puzzletime.git

Set up your machine:

    ./bin/setup

Make sure the tests pass:

    rake

Make your change. Add tests for your change. Make the tests pass:

    rake

Push to your fork and submit a pull request.

At this point you're waiting on us. We like to at least comment on pull requests
within one week. We may suggest some changes or improvements or alternatives.

Some things that will increase the chance that your pull request is accepted:

* Write tests.
* Follow [The Ruby Style Guide](https://github.com/bbatsov/ruby-style-guide) and [The Rails Style Guide](https://github.com/bbatsov/rails-style-guide).
* Write a good commit message (see below).

A more detailed development documentation in German can be found in [doc/development](doc/development).

## Commit messages

Follow [Conventional Commits](https://www.conventionalcommits.org/): a
`type(scope): summary` subject, e.g. `refactor(assets): shim forms`.

* **Types:** `feat`, `fix`, `docs`, `style`, `refactor`, `perf`, `test`,
  `build`, `ci`, `chore`, `revert`. Scope is optional; `!` marks a breaking change.
* Subject in the imperative, lowercase after the type, no trailing period, ≤ 72 chars.
* Keep the body short — bullet points where possible. Put longer rationale in the
  relevant doc and reference it from the body rather than inlining prose.

This is enforced by the `overcommit` `CommitMsg/MessageFormat` hook
(`.overcommit.yml`); run `overcommit --install` once after cloning.
