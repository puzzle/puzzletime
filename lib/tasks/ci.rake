# encoding: utf-8

desc 'Runs the tasks for a commit build'
task ci: ['log:clear',
          'db:migrate',
          'test']

namespace :ci do
  desc 'Runs the tasks for a nightly build, set TEST_REPORTS=true'
  task nightly: ['log:clear',
                 'db:migrate',
                 'test',
                 'erd',
                 'rubocop:report',
                 'brakeman',
                 'gemsurance']
end
