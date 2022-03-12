#!/usr/bin/env bash

set -e
set -x

bundle install

bundle exec rake db:prepare
