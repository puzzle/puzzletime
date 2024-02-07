# frozen_string_literal: true

class RemoveSuperfluousPrimaryKeysOnJoinTables < ActiveRecord::Migration[7.1]
  def up
    execute <<~SQL
      -- Remove the primary key constraints
      ALTER TABLE "order_contacts"     DROP CONSTRAINT IF EXISTS "order_contacts_pkey";
      ALTER TABLE "order_team_members" DROP CONSTRAINT IF EXISTS "order_team_members_pkey";

      -- Remove the primary key fields
      ALTER TABLE "order_contacts"     DROP COLUMN IF EXISTS "false";
      ALTER TABLE "order_team_members" DROP COLUMN IF EXISTS "false";

      -- Remove the primary key sequences
      DROP SEQUENCE IF EXISTS "order_contacts_false_seq";
      DROP SEQUENCE IF EXISTS "order_team_members_false_seq";
    SQL
  end

  def down
    # Can we safely ignore the rollback? The ids should have never been used anyways

    # execute <<~SQL
    #   -- Create the primary key sequences
    #   CREATE SEQUENCE order_contacts_false_seq;
    #   CREATE SEQUENCE order_team_members_false_seq;
    #
    #   -- Create the primary key columns on all tables
    #   ALTER TABLE "order_contacts"     ADD "false" bigint;
    #   ALTER TABLE "order_team_members" ADD "false" bigint;
    #
    #   -- Set the  fields as primary keys
    #   ALTER TABLE "order_contacts"     ADD PRIMARY KEY ("false");
    #   ALTER TABLE "order_team_members" ADD PRIMARY KEY ("false");
    # SQL
  end
end
