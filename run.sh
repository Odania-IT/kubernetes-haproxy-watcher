#!/usr/bin/env bash
DIR=$(dirname $0)
cd $DIR

bundle check || bundle install

./watch.rb
