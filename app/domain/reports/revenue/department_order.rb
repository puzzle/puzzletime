# frozen_string_literal: true

#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

module Reports
  module Revenue
    class DepartmentOrder < Base
      self.grouping_model = ::Department
      self.grouping_fk = :department_id

      def self.grouping_name
        "#{grouping_model.sti_name}_Order"
      end

      def self.grouping_name_human
        "#{grouping_model.model_name.human} - Aufträge"
      end
    end
  end
end
