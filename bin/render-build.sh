#!/usr/bin/env bash
set -o errexit

echo "🚀 Starting build process..."

echo "📦 Installing gems..."
bundle install

echo "🛠️ Precompiling assets..."
bundle exec rake assets:precompile

echo "🧹 Cleaning assets..."
bundle exec rake assets:clean

echo "🗄️ Running migrations..."
bundle exec rake db:migrate

echo "🌱 Seeding database..."
bundle exec rake db:seed

echo "✅ Build script finished!"
