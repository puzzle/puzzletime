# encoding: utf-8

#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.


desc 'Check for vulnerabilities in Ruby gems'
task :gemsurance do
  require 'gemsurance'
  gem_infos = Gemsurance::Runner.new.run.tap { |r| r.send(:generate_report) }.gem_infos
  if gem_infos.reject { |gem_info| %w(bundler nokogiri).include?(gem_info.name) }.any?(&:vulnerable?)
    fail('One or more of your Ruby gems has a known security vulnerability. ' \
         "Check #{Rails.root}/gemsurance_report.html for more info.")
  end
end
