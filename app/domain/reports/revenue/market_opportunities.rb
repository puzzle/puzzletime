# frozen_string_literal: true

#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

module Reports
  module Revenue
    class MarketOpportunities < Base
      self.grouping_model = ::MarketOpportunity
      self.grouping_fk = :market_opportunity_id
    end
  end
end
