#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.


class Reports::Workload::WorktimeEntry < Struct.new(*Reports::Workload::WORKTIME_FIELDS, :order_work_item)

  def absencetime?
    type == Absencetime.name
  end

  def ordertime?
    type == Ordertime.name
  end

  def external_client?
    Array.wrap(path_ids).exclude?(Company.work_item_id)
  end
end
