set -o errexit
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