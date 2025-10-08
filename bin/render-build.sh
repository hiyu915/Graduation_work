set -o errexit

# 既存の環境変数確認
echo "=== ENV VARS CHECK ==="
echo "RAILS_ENV=$RAILS_ENV"
echo "DATABASE_URL exists: $([ -n "$DATABASE_URL" ] && echo "YES" || echo "NO")"
echo "S3_ACCESS_KEY_ID=$S3_ACCESS_KEY_ID"
echo "S3_SECRET_ACCESS_KEY=$S3_SECRET_ACCESS_KEY"
echo "S3_BUCKET_NAME=$S3_BUCKET_NAME"
echo "S3_REGION=$S3_REGION"
echo "======================"

# Active Storage設定の詳細確認を追加
echo "=== ACTIVE STORAGE DEBUG ==="
echo "Rails.env: $RAILS_ENV"

# storage.ymlの内容確認
echo "--- storage.yml content ---"
cat config/storage.yml
echo "--- end storage.yml ---"

# production.rbの関連設定確認
echo "--- production.rb Active Storage setting ---"
grep -n "active_storage.service" config/environments/production.rb || echo "active_storage.service setting not found"
echo "--- end production.rb ---"
echo "=========================="

bundle install
bundle exec rake assets:precompile
bundle exec rake assets:clean

echo "=== DB MIGRATION START ==="
bundle exec rake db:migrate
echo "=== DB MIGRATION COMPLETE ==="

echo "=== DB SEED START ==="
bundle exec rake db:seed
echo "=== DB SEED COMPLETE ==="

echo "=== BUILD SCRIPT FINISHED ==="