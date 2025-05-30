#!/usr/bin/env bash
set -o errexit

echo "Installing gems..."
bundle install

echo "Precompiling assets..."
bundle exec rake assets:precompile

echo "Cleaning assets..."
bundle exec rake assets:clean

echo "Running DB migrations..."
bundle exec rake db:migrate

echo "Seeding database..."
bundle exec rake db:seed

echo "Build finished."
