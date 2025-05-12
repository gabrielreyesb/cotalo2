web: bundle exec puma -C config/puma.rb
release: NODE_OPTIONS=--openssl-legacy-provider bundle exec rake db:migrate && NODE_OPTIONS=--openssl-legacy-provider bundle exec rake assets:precompile 