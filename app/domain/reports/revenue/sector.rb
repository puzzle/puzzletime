# frozen_string_literal: true

#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

module Reports
  module Revenue
    class Sector < Base
      self.grouping_model = ::Sector
      self.grouping_fk = :sector_id

      def load_ordertimes(period = past_period)
        super
          .joins('LEFT JOIN clients ON clients.work_item_id = ANY (work_items.path_ids)')
          .joins('LEFT JOIN sectors ON sectors.id = clients.sector_id')
      end

      def load_plannings(period)
        super
          .joins('LEFT JOIN clients ON clients.work_item_id = ANY (work_items.path_ids)')
          .joins('LEFT JOIN sectors ON sectors.id = clients.sector_id')
      end
    end
  end
end
