#!/bin/bash

bundle install
bundle exec rackup config.ru -p 4567 -o 0.0.0.0 -s thin
