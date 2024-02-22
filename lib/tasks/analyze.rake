# frozen_string_literal: true

#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

desc 'Run brakeman'
task brakeman: :environment do
  FileUtils.rm_f('brakeman-output.tabs')

  begin
    Timeout.timeout(300) do
      sh 'brakeman'
    end
  rescue Timeout::Error
    puts "\nBrakeman took too long. Aborting."
  end
end

namespace :rubocop do
  desc 'Run .rubocop.yml and generate checkstyle report'
  task report: :environment do
    # do not fail if we find issues
    begin
      sh %w[rubocop
            --require rubocop/formatter/checkstyle_formatter
            --format RuboCop::Formatter::CheckstyleFormatter
            --no-color
            --out rubocop-results.xml].join(' ')
    rescue # rubocop:disable Style/RescueStandardError
      nil
    end
    true
  end

  desc 'Run .rubocop.yml on changed files'
  task changed: :environment do
    sh "git ls-files -m -o -x spec -x test | grep '\\.rb$' | xargs rubocop"
  end
end
