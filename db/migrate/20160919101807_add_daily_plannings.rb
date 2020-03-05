#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

class AddDailyPlannings < ActiveRecord::Migration[5.1]
  OLD_TABLE = :plannings
  NEW_TABLE = :plannings_new
  IGNORE_BEFORE = Date.today.beginning_of_year - 6.months
  UNLIMITED_REPEAT_DURATION = 6.months
  BATCH_SIZE = 1000

  def change
    create_table NEW_TABLE do |t|
      t.integer :employee_id, null: false, index: true
      t.integer :work_item_id, null: false, index: true
      t.date :date, null: false
      t.integer :percent, null: false
      t.boolean :definitive, default: false, null: false
    end
    add_index NEW_TABLE, [:employee_id, :work_item_id, :date], unique: true

    reversible do |dir|
      dir.up do
        migrate_order_closed
        migrate_plannings
      end
    end

    drop_table OLD_TABLE
    rename_table NEW_TABLE, OLD_TABLE
  end

  def migrate_order_closed
    WorkItem.joins(order: :status).
             where(order_statuses: { closed: true }, work_items: { closed: false }).
             update_all(closed: true)
  end

  def migrate_plannings
    offset = 0
    has_rows = true

    while has_rows
      query = old_table
        .project(Arel.sql('*'))
        .where(old_table[:end_week].gteq(IGNORE_BEFORE.cwyear * 100 + IGNORE_BEFORE.cweek)
                 .or(old_table[:end_week].eq(nil)))
        .take(BATCH_SIZE)
        .skip(offset)
      has_rows = select_all(query.to_sql).each { |row| migrate_row(row) }.length > 0
      offset += BATCH_SIZE
    end
  end

  private

  def migrate_row(row)
    (start_date(row)..end_date(row))
      .reject { |date| date.saturday? || date.sunday? }
      .each do |date|
        percent = percent_for_day(row, date)
        if percent > 0.0
          create_planning(employee_id: row['employee_id'],
                          work_item_id: row['work_item_id'],
                          date: date,
                          percent: percent,
                          definitive: row['definitive'] == 't')
        end
      end
  end

  def start_date(row)
    Date.commercial(row['start_week'].to_s[0, 4].to_i,
                    row['start_week'].to_s[4, 5].to_i, 1)
  end

  def end_date(row)
    if row['end_week'].present?
      Date.commercial(row['end_week'].to_s[0, 4].to_i,
                      row['end_week'].to_s[4, 5].to_i, 7)
    else
      Date.today.beginning_of_week + UNLIMITED_REPEAT_DURATION
    end
  end

  def percent_for_day(row, date)
    if row['is_abstract'] == 't'
      row['abstract_amount'].to_i
    else
      weekday = date.strftime('%A').downcase
      (row["#{weekday}_am"] == 't' ? 50 : 0) +
        (row["#{weekday}_pm"] == 't' ? 50 : 0)
    end
  end

  def create_planning(entry)
    insert_planning(entry) unless planning_exists?(entry)
  end

  def planning_exists?(entry)
    condition = [:employee_id, :work_item_id, :date]
      .map { |k| new_table[k].eq(entry[k]) }
      .reduce(:and)
    query = new_table
      .project(new_table[:id].count.as('count'))
      .where(condition)
    select_one(query.to_sql)['count'] != '0'
  end

  def insert_planning(entry)
    query = Arel::Nodes::InsertStatement.new
    query.relation = new_table
    query.columns = entry.keys.map { |k| new_table[k] }
    query.values = Arel::Nodes::Values.new(entry.values, query.columns)
    insert(query.to_sql)
  end

  def old_table
    @old_table ||= Arel::Table.new(OLD_TABLE)
  end

  def new_table
    @new_table ||= Arel::Table.new(NEW_TABLE)
  end
end
