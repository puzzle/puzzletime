#!/bin/bash

# Create data volumes and adjust permissions for the docker containers.
#
# Any files written by the container will belong to the userid the container
# runs as but have group ownership of the current users' primary group.
# This prevents the containers from creating files that are not
# manageable without root priviledges.

project_root=$(dirname $0)/..
cd $project_root

primary_group=$(groups | cut -f 1 -d ' ')

mkdir -p postgres_files

echo "Going to sudo to create directories and mounts with correct permissions."
echo "You can safely ignore 'fuse: mountpoint is not empty' warnings."
echo

sudo mkdir -p tmp
sudo chown 1001:$primary_group tmp
sudo chmod g+w tmp

sudo mkdir -p /mnt/puzzletime_rails_root
sudo mkdir -p /mnt/puzzletime_postgres_files
sudo bindfs -u 1001 -g $primary_group --create-for-user=1001 --create-for-group=$primary_group . /mnt/puzzletime_rails_root
sudo bindfs -u 999 -g $primary_group --create-for-user=1001 --create-for-group=$primary_group ./postgres_files /mnt/puzzletime_postgres_files
