namespace :assets do
  desc "Precompile assets"
  task :precompile => :environment do
    Rake::Task['assets:precompile'].invoke
  end
end 