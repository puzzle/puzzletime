# frozen_string_literal: true

# Add your own tasks in files placed in lib/tasks ending in .rake,
# for example lib/tasks/capistrano.rake, and they will automatically be available to Rake.

require File.expand_path('config/application', __dir__)

unless Rails.env.production?
  require 'rails-erd'
  require 'bundler/audit/task'
  Bundler::Audit::Task.new
end

Rails.application.load_tasks
