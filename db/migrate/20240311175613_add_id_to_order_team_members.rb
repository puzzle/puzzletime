# frozen_string_literal: true

class AddIdToOrderTeamMembers < ActiveRecord::Migration[7.1]
  def change
    remove_index :order_team_members, column: :employee_id
    remove_index :order_team_members, column: :order_id

    reversible do |dir|
      dir.up { deduplicate_entries }
    end

    add_column :order_team_members, :id, :primary_key
    add_index :order_team_members, %i[employee_id order_id], unique: true
  end

  private

  def deduplicate_entries
    execute <<~SQL.squish
      DELETE FROM "order_team_members"
      WHERE "ctid" IN (
        SELECT "ctid"
        FROM (
          SELECT
            "ctid",
            "employee_id",
            "order_id",
            row_number() OVER (
              PARTITION BY "employee_id", "order_id"
              ORDER BY "employee_id", "order_id"
            ) AS "rnum"
          FROM "order_team_members"
        ) "t"
        WHERE "t"."rnum" > 1
      );
    SQL
  end
end
