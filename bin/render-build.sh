bundle install
bundle exec rake assets:precompile
bundle exec rake assets:clean
bin/rails db:migrate