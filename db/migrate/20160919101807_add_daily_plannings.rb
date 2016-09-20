class AddDailyPlannings < ActiveRecord::Migration
  OLD_TABLE = :plannings
  NEW_TABLE = :plannings_new
  IGNORE_BEFORE = Date.today.beginning_of_month - 1.months
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
        migrate_data
      end
    end

    drop_table OLD_TABLE
    rename_table NEW_TABLE, OLD_TABLE
  end

  def migrate_data
    offset = 0
    has_rows = true

    while has_rows
      plannings = Arel::Table.new(OLD_TABLE)
      query = plannings
        .project(Arel.sql('*'))
        .where(plannings[:end_week].gteq(IGNORE_BEFORE.cwyear * 100 + IGNORE_BEFORE.cweek)
                 .or(plannings[:end_week].eq(nil)))
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
    query = Arel::Nodes::InsertStatement.new
    query.relation = Arel::Table.new(NEW_TABLE)
    query.columns = entry.keys.map { |k| Arel::Table.new(NEW_TABLE)[k] }
    query.values = Arel::Nodes::Values.new(entry.values, query.columns)
    insert(query.to_sql)
  end
end

