# Welcome to PuzzleTime

PuzzleTime is an open source time tracking and resource planning web application for SMEs.

![Rails Unit Tests](https://github.com/puzzle/puzzletime/workflows/Rails%20Unit%20Tests/badge.svg)
[![GitHub](https://img.shields.io/github/license/puzzle/puzzletime)](https://github.com/puzzle/puzzletime/blob/master/LICENSE)

## Development

PuzzleTime is a Ruby on Rails application that runs on Ruby >= 2.2.2 and Rails 5.
To get going, after you got a copy of PuzzleTime, issue the following commands in the main
directory:

    bin/setup            # install gem dependencies and setup database (PostgreSQL)
    rake                 # run all the tests
    rails db:setup       # prepare database
    rails server         # start the rails server

A more detailed development documentation in German can be found in [doc/development](doc/development/README.md). This is where you also find some [Deployment](doc/development/03_deployment.md) instructions

## Heroku

The current master branch needs to be modified slightly for heroku. To achieve this we create a new branch

    git checkout -b heroku_setup

Then we make the require changes for Memcache and Sendfile to [production.rb](config/environments/production.rb)

    config.action_dispatch.x_sendfile_header = nil

    config.cache_store = :mem_cache_store,
      (ENV["MEMCACHIER_SERVERS"] || "").split(","),
      {:username => ENV["MEMCACHIER_USERNAME"],
      :password => ENV["MEMCACHIER_PASSWORD"],
      :failover => true,
      :socket_timeout => 1.5,
      :socket_failure_delay => 0.2,
      :down_retry_delay => 60
      }

Then we commit these changes to our branch

    git commit -am 'Changes for heroku'

Now we can deploy with these modifications to heroku 

    heroku create
    git push heroku heroku_setup:master

    heroku config:set RAILS_SERVE_STATIC_FILES=true 
    heroku run rails assets:precompile

    heroku addons:create memcachier:dev

    heroku run rails db:migrate 
    heroku run 'ln -s /app/db/seeds/development /app/db/seeds/production && rails db:seed'
    heroku restart
    heroku open

Then login using (username: mw, password: a) as credentials


## License

PuzzleTime is released under the GNU Affero General Public License.
Copyright 2006-2022 by [Puzzle ITC GmbH](http://puzzle.ch).
See LICENSE for more details.
