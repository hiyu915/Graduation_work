#!/usr/bin/env bash
set -o errexit

echo "Terminating existing database connections..."
psql $DATABASE_URL -c "SELECT pg_terminate_backend(pid) FROM pg_stat_activity WHERE datname = 'repilog' AND pid <> pg_backend_pid();"

echo "Running bundle install..."
bundle install

echo "Cleaning assets..."
bin/rails assets:clobber

echo "Precompiling assets..."
bin/rails assets:precompile

echo "Resetting and migrating database..."
DISABLE_DATABASE_ENVIRONMENT_CHECK=1 bin/rails db:migrate:reset

echo "Seeding database..."
bin/rails db:seed

echo "Build script completed."