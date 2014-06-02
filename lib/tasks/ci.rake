# encoding: utf-8

desc "Runs the tasks for a commit build"
task :ci => ['log:clear',
             'db:migrate',
             'test']

namespace :ci do
  desc "Runs the tasks for a nightly build"
  task :nightly => ['log:clear',
                    'db:migrate',
                    'erd',
                    'test',
                    'rubocop:report',
                    'brakeman',
                    ]

end
