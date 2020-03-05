#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

module Reports::Revenue
  class Service < Base
    self.grouping_model = ::Service
    self.grouping_fk = :service_id
  end
end
