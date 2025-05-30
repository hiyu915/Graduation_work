#!/usr/bin/env bash
set -o errexit

echo "Running bundle install..."
bundle install

echo "Precompiling assets..."
bundle exec rake assets:precompile

echo "Cleaning assets..."
bundle exec rake assets:clean

echo "Running migrations..."
bin/rails db:migrate

echo "Seeding database..."
bin/rails db:seed

echo "Build script finished."
