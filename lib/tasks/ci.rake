# frozen_string_literal: true

#  Copyright (c) 2006-2019, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.
GECKO_DOWNLOAD_URL = 'https://github.com/mozilla/geckodriver/releases/download/v0.23.0/geckodriver-v0.23.0-linux64.tar.gz'

desc 'Runs the tasks for a commit build'
task ci: ['log:clear',
          'db:migrate',
          'ci:prepare',
          'test']

namespace :ci do
  desc 'Runs the tasks for a nightly build, set TEST_REPORTS=true'
  task nightly: ['log:clear',
                 'db:migrate',
                 'ci:prepare',
                 'test',
                 'erd',
                 'rubocop:report',
                 'brakeman',
                 'bundle:audit']

  desc 'Prepare the system for integration tests'
  task prepare: ['vendor/tools/geckodriver/geckodriver'] do |target|
    puts 'Modifying $PATH to prepend geckodriver'
    target = Pathname.new(target.prerequisites.first)
    modify_path(target)
  end

  directory 'vendor/tools/geckodriver/'

  file 'vendor/tools/geckodriver/geckodriver' => ['vendor/tools/geckodriver/'] do |target|
    puts 'No local geckodriver found.'
    target = Pathname.new(target.name)
    if system_geckodriver
      puts "System geckodriver will be used: #{system_geckodriver}"
      symlink_geckodriver(target)
    else
      puts "Geckodriver will be downloaded from: #{GECKO_DOWNLOAD_URL}"
      download_geckodriver(target)
    end
    puts 'Geckodriver prepared'
  end
end

private

def system_geckodriver
  @system_geckodriver ||=
    begin
      path = Pathname.new(`which geckodriver`.chomp)
      path if path.exist?
    end
end

def symlink_geckodriver(target)
  File.symlink(system_geckodriver, target)
end

def download_geckodriver(target)
  `wget -c #{GECKO_DOWNLOAD_URL} -O - | tar -xz -C #{target.dirname}`
end

def modify_path(target)
  ENV['PATH'] = "#{target.dirname}:#{ENV.fetch('PATH', nil)}"
end
