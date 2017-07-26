# encoding: utf-8

#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.


 class EmployeeMasterData < ActiveRecord::Migration[5.1]
  def change
    add_column :employees, :phone_office, :string
    add_column :employees, :phone_private, :string
    add_column :employees, :street, :string
    add_column :employees, :postal_code, :string
    add_column :employees, :city, :string
    add_column :employees, :birthday, :date
    add_column :employees, :emergency_contact_name, :string
    add_column :employees, :emergency_contact_phone, :string
    add_column :employees, :marital_status, :integer
    add_column :employees, :social_insurance, :string
    add_column :employees, :crm_key, :string

    create_table :employment_roles do |t|
      t.string :name, null: false
      t.boolean :billable, null: false
      t.boolean :level, null: false
      t.belongs_to :employment_role_category
    end

    create_table :employment_role_levels do |t|
      t.string :name, null: false
    end

    create_table :employment_role_categories do |t|
      t.string :name, null: false
    end

    create_table :employment_roles_employments do |t|
      t.belongs_to :employment, null: false
      t.belongs_to :employment_role, null: false
      t.belongs_to :employment_role_level
      t.decimal :percent, precision: 5, scale: 2, null: false
    end

    add_index :employment_roles_employments,
              [:employment_id, :employment_role_id],
              name: 'index_unique_employment_employment_role',
              unique: true
  end
end
