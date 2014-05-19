# Add your own tasks in files placed in lib/tasks ending in .rake,
# for example lib/tasks/capistrano.rake, and they will automatically be available to Rake.

require File.expand_path('../config/application', __FILE__)

require 'ci/reporter/rake/minitest' unless Rails.env.production?

if Rails.env.development?
  require 'rails-erd'
end

Rails.application.load_tasks
