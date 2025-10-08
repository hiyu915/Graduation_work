set -o errexit

# 環境変数確認
echo "=== ENV VARS CHECK ==="
echo "RAILS_ENV=$RAILS_ENV"
echo "S3_ACCESS_KEY_ID=$S3_ACCESS_KEY_ID"
echo "S3_SECRET_ACCESS_KEY=$S3_SECRET_ACCESS_KEY"
echo "S3_BUCKET_NAME=$S3_BUCKET_NAME"
echo "S3_REGION=$S3_REGION"
echo "======================"

bundle install
bundle exec rake assets:precompile
bundle exec rake assets:clean
bundle exec rake db:migrate
bundle exec rake db:seed
