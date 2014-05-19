# encoding: utf-8

desc "Runs the tasks for a commit build"
task :ci => ['log:clear',
             'db:migrate',
             'ci:setup:minitest',
             'test']

namespace :ci do
  desc "Runs the tasks for a nightly build"
  task :nightly => ['log:clear',
                    'db:migrate',
                    'erd',
                    'ci:setup:minitest',
                    'test',
                    'rubocop:report',
                    'brakeman',
                    ]

end
