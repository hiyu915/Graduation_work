#!/usr/bin/env bash
set -o errexit

echo "Installing gems..."
bundle install

echo "Precompiling assets..."
bundle exec rake assets:precompile

echo "Cleaning old assets..."
bundle exec rake assets:clean

echo "Running db:migrate..."
bundle exec rake db:migrate

echo "Seeding data..."
bundle exec rake db:seed
