#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

class Reports::Workload::OrdertimeEntry < Struct.new(:work_item, :hours, :billability)
  delegate :id, to: :work_item

  def label
    work_item.path_shortnames
  end

  def description
    work_item.name
  end

  def billability_percent
    100 * billability
  end
end
