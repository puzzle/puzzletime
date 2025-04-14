# Welcome to PuzzleTime

PuzzleTime is an open source time tracking and resource planning web application for SMEs.

[![Rails Test](https://github.com/puzzle/puzzletime/workflows/reusable-test.yaml/badge.svg)](https://github.com/puzzle/puzzletime/workflows/reusable-test.yaml)
[![GitHub](https://img.shields.io/github/license/puzzle/puzzletime)](https://github.com/puzzle/puzzletime/blob/master/LICENSE)

## Development

PuzzleTime is a Ruby on Rails application that runs on Ruby >= 2.2.2 and Rails 5.
To get going, after you got a copy of PuzzleTime, issue the following commands in the main
directory:

    bin/setup            # install gem dependencies and setup database (PostgreSQL)
    rake                 # run all the tests
    rails db:setup       # prepare database
    rails server         # start the rails server

A more detailed development documentation in German can be found in [doc/development](doc/development/README.md). This is where you also find some [Deployment](doc/development/02_deployment.md) instructions

## License

PuzzleTime is released under the GNU Affero General Public License.
Copyright 2006-2025 by [Puzzle ITC AG](https://www.puzzle.ch).
See [LICENSE](LICENSE) for more details.
