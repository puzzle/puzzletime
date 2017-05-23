#!/bin/sh

set -ex

if [ $(which s2i) -ne 0 ]; then
    echo "s2i missing, install latest binary from https://github.com/openshift/source-to-image/releases"
    exit 1
fi

if [ "$1" = "production" ]; then
    bundle_without="development:test"
    image="puzzle.ch/puzzletime"
else # Development build
    bundle_without="unused_group"
    image="puzzle.ch/puzzletime:development"
fi

build_root=$(readlink -f $(dirname $0))
app_root=$build_root/..
release_root=$app_root/tmp/release

mkdir -p $release_root
rm -rf $release_root/*

cd $app_root
git archive --format=tar HEAD | (cd $release_root && tar xf -)

cd $release_root

s2i build --incremental=true \
    -e BUNDLE_WITHOUT=$bundle_without \
    . puzzle/ose3-rails $image
