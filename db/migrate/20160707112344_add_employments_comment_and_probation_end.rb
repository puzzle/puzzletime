# encoding: utf-8

#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.


class AddEmploymentsCommentAndProbationEnd < ActiveRecord::Migration[5.1]
  def change
    add_column :employments, :comment, :string
    add_column :employments, :probation_period_end_date, :date
  end
end
