# encoding: utf-8

desc "Runs the tasks for a commit build"
task :ci => ['log:clear',
             'db:migrate',
             'test:units',
             'test:integration']

namespace :ci do
  desc "Runs the tasks for a nightly build, set TEST_REPORTS=true"
  task :nightly => ['log:clear',
                    'db:migrate',
                    'test:units',  # must be before others to get coverage
                    'test:integration',
                    'erd',
                    'rubocop:report',
                    'brakeman',
                    'gemsurance',
                    ]

end
