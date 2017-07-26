# encoding: utf-8

#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.



namespace :test do
  desc 'Run only non-integration tests'
  task unit: 'test:prepare' do
    $LOAD_PATH << 'test'
    Minitest.rake_run(['test/models', 'test/helpers', 'test/controllers', 'test/domain'])
  end

  desc 'Run tests for domain'
  task domain: 'test:prepare' do
    $LOAD_PATH << 'test'
    Minitest.rake_run(['test/domain'])
  end
end
