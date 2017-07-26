# encoding: utf-8

#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.


class CreateCustomLists < ActiveRecord::Migration[5.1]
  def up
    create_table :custom_lists do |t|
      t.string :name, null: false
      t.belongs_to :employee
      t.string :item_type, null: false
      t.integer :item_ids, array: true, null: false
    end

    migrate_lists

    drop_table :employee_lists_employees
    drop_table :employee_lists
  end

  def down
    drop_table :custom_lists

    create_table :employee_lists_employees, id: false do |t|
      t.belongs_to :employee
      t.belongs_to :employee_list
    end

    create_table :employee_lists do |t|
      t.belongs_to :employee
      t.string :title
    end
  end

  private

  def migrate_lists
    groups = grouped_employee_ids
    load_employee_lists.each do |row|
      insert_custom_list(row['employee_id'].to_i, row['title'], groups[row['id'].to_i])
    end
  end

  def load_employee_lists
    select_all(Arel::Table.new(:employee_lists).project(Arel.sql('*')).to_sql)
  end

  def grouped_employee_ids
    table = Arel::Table.new(:employee_lists_employees)
    query = table.project(Arel.sql('*'))
    select_all(query.to_sql).to_a.group_by { |row| row['employee_list_id'].to_i }.tap do |groups|
      groups.values.each do |list|
        list.collect! { |row| row['employee_id'].to_i }
      end
    end
  end

  def insert_custom_list(employee_id, name, ids)
    CustomList.create!(employee_id: employee_id,
                       name: name.presence || 'Meine Liste',
                       item_type: 'Employee',
                       item_ids: ids)
  end

end
