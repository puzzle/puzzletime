#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.


module Invoicing
  class Error < StandardError
    attr_reader :code, :data

    def initialize(message, code = nil, data = nil)
      super(message)
      @code = code
      @data = data
    end
  end
end
