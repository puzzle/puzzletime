# Add your own tasks in files placed in lib/tasks ending in .rake,
# for example lib/tasks/capistrano.rake, and they will automatically be available to Rake.

require(File.join(File.dirname(__FILE__), 'config', 'boot'))

require 'rake'
require 'rake/testtask'
require 'rake/rdoctask'

require 'tasks/rails'

#Rake::TaskManager.class_eval do
#  def delete_task(task_name)
#    @tasks.delete(task_name.to_s)
#  end
#  Rake.application.delete_task("db:test:purge")
#  Rake.application.delete_task("db:test:prepare")
#end

#namespace :db do
#  namespace :test do
#    task :purge => [:environment] do
#      ActiveRecord::Base.establish_connection(ActiveRecord::Base.configurations['test'])
#      ActiveRecord::Migrator.migrate("db/migrate/", 0)
#    end

#    task :prepare => [:environment, :purge] do
#      ActiveRecord::Base.establish_connection(ActiveRecord::Base.configurations['test'])
#      ActiveRecord::Migration.verbose = false
#      ActiveRecord::Migrator.migrate("db/migrate/")
#    end
#  end
#end
