## Dockerized Development

There is a dockerized development environment, a work in progress.

### Prerequisites

    sudo apt install bindfs

    # Mount targets with correct permissions
    sudo apt install bindfs
    bin/prepare_dev_env.sh

### Start dev environment

    bin/build_dev_image.sh # (once)
    bin/start_dev_env.sh

### Useful commands

View logs

    docker-compose logs -f rails

Migrate database

    docker exec -it puzzletime_rails_1 bash -c 'bundle exec rake db:migrate'

Rails console

    docker exec -it puzzletime_rails_1 bash -c 'bundle exec rails c'

Run tests

    docker exec -it puzzletime_rails_1 bash -c 'RAILS_ENV=test bundle exec rake test'

### Load dump

    docker cp dump.sql puzzletime_database_1:/tmp
    docker exec -it puzzletime_database_1 bash -c 'psql --user puzzletime puzzletime < /tmp/dump.sql'

### Misc

    docker exec -it puzzletime_rails_1 bash -c 'bundle exec rake -T'
