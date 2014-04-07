# Add your own tasks in files placed in lib/tasks ending in .rake,
# for example lib/tasks/capistrano.rake, and they will automatically be available to Rake.

require(File.join(File.dirname(__FILE__), 'config', 'boot'))

require 'rake'
require 'rake/testtask'
require 'rdoc/task' 

require 'tasks/rails'

load "vendor/plugins/tarantula/lib/relevance/tasks/tarantula_tasks.rake"
#Dir["relevance/tasks/*.rake"].each {|f| load f }