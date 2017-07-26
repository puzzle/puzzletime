# encoding: utf-8

#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.


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
