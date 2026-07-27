# frozen_string_literal: true

#  Copyright (c) 2006-2026, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

# All three columns are nullable by accident rather than by design. Rails >= 5
# makes `belongs_to` required by default, so the models validate presence
# already; this brings the database in line so it cannot be bypassed.
#
# `worktimes.employee_id` is included deliberately even though production still
# had 4 rows without an employee (977698, 977699, 1008347, 1008350) when this was
# written. Those are expected to be cleared before the upgrade ships, and this
# migration is the gate that proves it: if any remain, the release fails here
# with their ids rather than shipping a table that contradicts its own model.
# Do not "fix" a failure by relaxing the constraint — classify the rows.
#
# employments and authentications are small, and worktimes is scanned once, so
# the ACCESS EXCLUSIVE lock SET NOT NULL takes is short-lived.
class RequireEmployeeOnWorktimesEmploymentsAndAuthentications < ActiveRecord::Migration[7.1]
  TABLES = %w[worktimes employments authentications].freeze

  def up
    raise_on_orphans

    TABLES.each { |table| change_column_null table, :employee_id, false }
  end

  def down
    TABLES.each { |table| change_column_null table, :employee_id, true }
  end

  private

  # Fail loudly with the offending ids rather than letting Postgres report a
  # bare constraint violation with no way to find the rows.
  def raise_on_orphans
    offenders = TABLES.filter_map do |table|
      ids = select_values("SELECT id FROM #{table} WHERE employee_id IS NULL")
      "#{table}: #{ids.size} row(s) (ids: #{ids.join(', ')})" if ids.any?
    end
    return if offenders.empty?

    raise <<~MESSAGE
      Rows without an employee_id are still present:
        #{offenders.join("\n  ")}
      Assign each row to an employee, or delete it if it is not a real record.
      This is a data decision — do not drop the NOT NULL constraint to get past it.
    MESSAGE
  end
end
