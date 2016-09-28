require 'test_helper'
require Dir[Rails.root.join('db/migrate/*_add_daily_plannings.rb')].first

class AddDailyPlanningsTest < ActiveSupport::TestCase
  setup :create_weekly_plannings_table, :insert_weekly_plannings, :delete_fixtures

  test 'migrates old weekly plannings to new daily plannings' do
    AddDailyPlannings::OLD_TABLE = :plannings_old
    AddDailyPlannings::NEW_TABLE = :plannings
    AddDailyPlannings::IGNORE_BEFORE = Date.new(2016, 9, 1)
    migration.migrate_plannings

    plannings = Planning.where(work_item_id: 3)
    assert_equal 5, plannings.count
    assert plannings.pluck(:employee_id).all? { |v| v == 1 }
    assert plannings.pluck(:work_item_id).all? { |v| v == 3 }
    assert plannings.pluck(:percent).all? { |v| v == 75 }
    assert plannings.pluck(:definitive).all?
    assert_equal [Date.new(2016, 10, 3),
                  Date.new(2016, 10, 4),
                  Date.new(2016, 10, 5),
                  Date.new(2016, 10, 6),
                  Date.new(2016, 10, 7)], plannings.pluck(:date)

    plannings = Planning.where(work_item_id: 4)
    assert_equal 15, plannings.count
    assert plannings.pluck(:employee_id).all? { |v| v == 1 }
    assert plannings.pluck(:work_item_id).all? { |v| v == 4 }
    assert plannings.pluck(:percent).all? { |v| v == 75 }
    assert plannings.pluck(:definitive).all?
    assert_equal [Date.new(2016, 10, 3),
                  Date.new(2016, 10, 4),
                  Date.new(2016, 10, 5)], plannings.pluck(:date)[0..2]
    assert_equal [Date.new(2016, 10, 19),
                  Date.new(2016, 10, 20),
                  Date.new(2016, 10, 21)], plannings.pluck(:date)[-3..-1]

    plannings = Planning.where(work_item_id: 5)
    assert_equal 120, plannings.count
    assert plannings.pluck(:employee_id).all? { |v| v == 1 }
    assert plannings.pluck(:work_item_id).all? { |v| v == 5 }
    assert plannings.pluck(:percent).all? { |v| v == 75 }
    assert plannings.pluck(:definitive).all?
    assert_equal [Date.new(2016, 10, 3),
                  Date.new(2016, 10, 4),
                  Date.new(2016, 10, 5)], plannings.pluck(:date)[0..2]
    assert_equal [Date.new(2017, 3, 15),
                  Date.new(2017, 3, 16),
                  Date.new(2017, 3, 17)], plannings.pluck(:date)[-3..-1]

    plannings = Planning.where(work_item_id: 6)
    assert_equal 5, plannings.count
    assert plannings.pluck(:employee_id).all? { |v| v == 1 }
    assert plannings.pluck(:work_item_id).all? { |v| v == 6 }
    assert plannings.pluck(:percent).all? { |v| v == 20 }
    assert plannings.pluck(:definitive).none?
    assert_equal [Date.new(2016, 10, 3),
                  Date.new(2016, 10, 4),
                  Date.new(2016, 10, 5),
                  Date.new(2016, 10, 6),
                  Date.new(2016, 10, 7)], plannings.pluck(:date)

    plannings = Planning.where(work_item_id: 7)
    assert_equal 5, plannings.count
    assert plannings.pluck(:employee_id).all? { |v| v == 1 }
    assert plannings.pluck(:work_item_id).all? { |v| v == 7 }
    assert_equal [100, 50, 50, 50, 50], plannings.pluck(:percent)
    assert plannings.pluck(:definitive).all?
    assert_equal [Date.new(2016, 10, 3),
                  Date.new(2016, 10, 4),
                  Date.new(2016, 10, 5),
                  Date.new(2016, 10, 6),
                  Date.new(2016, 10, 7)], plannings.pluck(:date)

    plannings = Planning.where(work_item_id: 8)
    assert_equal 48, plannings.count
    assert plannings.pluck(:employee_id).all? { |v| v == 1 }
    assert plannings.pluck(:work_item_id).all? { |v| v == 8 }
    assert_equal [100, 50, 100, 50], plannings.pluck(:percent)[0..3]
    assert_equal [100, 50, 100, 50], plannings.pluck(:percent)[-4..-1]
    assert plannings.pluck(:definitive).all?
    assert_equal [Date.new(2016, 10, 3),
                  Date.new(2016, 10, 4),
                  Date.new(2016, 10, 10),
                  Date.new(2016, 10, 11)], plannings.pluck(:date)[0..3]
    assert_equal [Date.new(2017, 3, 6),
                  Date.new(2017, 3, 7),
                  Date.new(2017, 3, 13),
                  Date.new(2017, 3, 14)], plannings.pluck(:date)[-4..-1]
  end

  private

  def migration
    @migration ||= AddDailyPlannings.new
  end

  def connection
    @connection ||= ActiveRecord::Base.connection
  end

  def create_weekly_plannings_table
    query = 'CREATE TABLE plannings_old' \
            '(' \
            '  id serial NOT NULL,' \
            '  employee_id integer NOT NULL,' \
            '  start_week integer NOT NULL,' \
            '  end_week integer,' \
            '  definitive boolean NOT NULL DEFAULT false,' \
            '  description text,' \
            '  monday_am boolean NOT NULL DEFAULT false,' \
            '  monday_pm boolean NOT NULL DEFAULT false,' \
            '  tuesday_am boolean NOT NULL DEFAULT false,' \
            '  tuesday_pm boolean NOT NULL DEFAULT false,' \
            '  wednesday_am boolean NOT NULL DEFAULT false,' \
            '  wednesday_pm boolean NOT NULL DEFAULT false,' \
            '  thursday_am boolean NOT NULL DEFAULT false,' \
            '  thursday_pm boolean NOT NULL DEFAULT false,' \
            '  friday_am boolean NOT NULL DEFAULT false,' \
            '  friday_pm boolean NOT NULL DEFAULT false,' \
            '  created_at timestamp without time zone,' \
            '  updated_at timestamp without time zone,' \
            '  is_abstract boolean,' \
            '  abstract_amount numeric,' \
            '  work_item_id integer NOT NULL,' \
            '  CONSTRAINT plannings_old_pkey PRIMARY KEY (id)' \
            ');'
    connection.execute(query)
  end

  def insert_weekly_plannings
    query = 'INSERT INTO plannings_old ' \
              '(employee_id,work_item_id,start_week,end_week,definitive,is_abstract,abstract_amount) ' \
              'VALUES (1,3,201640,201640,TRUE,TRUE,75.0);' \
            'INSERT INTO plannings_old ' \
              '(employee_id,work_item_id,start_week,end_week,definitive,is_abstract,abstract_amount) ' \
              'VALUES (1,4,201640,201642,TRUE,TRUE,75.0);' \
            'INSERT INTO plannings_old ' \
              '(employee_id,work_item_id,start_week,end_week,definitive,is_abstract,abstract_amount) ' \
              'VALUES (1,5,201640,NULL,TRUE,TRUE,75.0);' \
            'INSERT INTO plannings_old ' \
              '(employee_id,work_item_id,start_week,end_week,definitive,is_abstract,abstract_amount) ' \
              'VALUES (1,6,201640,201640,FALSE,TRUE,20.0);' \
            'INSERT INTO plannings_old ' \
              '(employee_id,work_item_id,start_week,end_week,definitive,is_abstract,monday_am,monday_pm,tuesday_am,tuesday_pm,wednesday_am,wednesday_pm,thursday_am,thursday_pm,friday_am,friday_pm) ' \
              'VALUES (1,7,201640,201640,TRUE,FALSE,TRUE,TRUE,TRUE,FALSE,FALSE,TRUE,TRUE,FALSE,FALSE,TRUE);' \
            'INSERT INTO plannings_old ' \
              '(employee_id,work_item_id,start_week,end_week,definitive,is_abstract,monday_am,monday_pm,tuesday_am,tuesday_pm,wednesday_am,wednesday_pm,thursday_am,thursday_pm,friday_am,friday_pm) ' \
              'VALUES (1,8,201640,NULL,TRUE,FALSE,TRUE,TRUE,TRUE,FALSE,FALSE,FALSE,FALSE,FALSE,FALSE,FALSE);'
    connection.execute(query)
  end

  def delete_fixtures
    Planning.destroy_all
  end
end
