#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

class AddOrdersCompletedMonthEndAt < ActiveRecord::Migration[5.1]
  def change
    add_column :orders, :completed_month_end_at, :date
  end
end
