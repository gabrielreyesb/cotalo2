namespace :assets do
  desc "Precompile assets with legacy OpenSSL provider"
  task :precompile_with_legacy_ssl => :environment do
    ENV['NODE_OPTIONS'] = '--openssl-legacy-provider'
    Rake::Task['assets:precompile'].invoke
  end
end 