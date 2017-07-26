# encoding: utf-8

#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.


if defined?(BetterErrors) && ENV['BETTER_ERRORS_URL'].present?
  BetterErrors.editor = proc { |full_path, line|
    namespace = OpenStruct.new(full_path: "/hello/world", line: 123)
    Haml::Engine.new(ENV['BETTER_ERRORS_URL']).render(namespace.instance_eval { binding})
  }
end