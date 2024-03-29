# frozen_string_literal: true

#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

require 'test_helper'

class CreatorTest < ActiveSupport::TestCase
  test '#create_or_update runs validations and returns false if invalid' do
    c = Plannings::Creator.new({})
    assert_difference 'Planning.count', 0 do
      assert_not c.create_or_update
    end
    assert_nil c.plannings
    assert_not_empty c.errors
  end

  test '#create_or_update with no new/existing items does nothing' do
    c = Plannings::Creator.new({ planning: { percent: 50 } })
    assert_difference 'Planning.count', 0 do
      assert c.create_or_update
    end
    assert_empty c.plannings
    assert_empty c.errors
  end

  test '#create_or_update creates new plannings' do
    params = { planning: { percent: 50, definitive: true },
               items: [
                 { employee_id: employees(:pascal).id.to_s,
                   work_item_id: work_items(:puzzletime).id.to_s,
                   date: '2000-01-03' },
                 { employee_id: employees(:pascal).id.to_s,
                   work_item_id: work_items(:puzzletime).id.to_s,
                   date: '2000-01-04' },
                 { employee_id: employees(:mark).id.to_s,
                   work_item_id: work_items(:puzzletime).id.to_s,
                   date: '2000-01-04' }
               ] }
    c = Plannings::Creator.new(ActionController::Parameters.new(params))
    assert_difference 'Planning.count', 3 do
      assert c.create_or_update
    end

    assert_equal 3, c.plannings.length
    assert_empty c.errors

    assert_equal Date.new(2000, 1, 3), c.plannings.first.date
    assert_equal employees(:pascal).id, c.plannings.first.employee_id
    assert_equal work_items(:puzzletime).id, c.plannings.first.work_item_id

    assert_equal Date.new(2000, 1, 4), c.plannings.second.date
    assert_equal employees(:pascal).id, c.plannings.second.employee_id

    assert_equal Date.new(2000, 1, 4), c.plannings.third.date
    assert_equal employees(:mark).id, c.plannings.third.employee_id

    assert(c.plannings.all? { |p| p.percent == 50 && p.definitive })
  end

  test '#create_or_update updates existing plannings and changes only present values' do
    p1 = Planning.create!(employee_id: employees(:pascal).id,
                          work_item_id: work_items(:puzzletime).id,
                          date: '2000-01-03',
                          percent: 50,
                          definitive: true)
    p2 = Planning.create!(employee_id: employees(:pascal).id,
                          work_item_id: work_items(:puzzletime).id,
                          date: '2000-01-04',
                          percent: 50,
                          definitive: true)
    p3 = Planning.create!(employee_id: employees(:mark).id,
                          work_item_id: work_items(:puzzletime).id,
                          date: '2000-01-04',
                          percent: 50,
                          definitive: true)

    params = { planning: { percent: 25, definitive: false },
               items: [
                 { employee_id: employees(:pascal).id.to_s,
                   work_item_id: work_items(:puzzletime).id.to_s,
                   date: '2000-01-03' },
                 { employee_id: employees(:mark).id.to_s,
                   work_item_id: work_items(:puzzletime).id.to_s,
                   date: '2000-01-04' }
               ] }
    c = Plannings::Creator.new(ActionController::Parameters.new(params))
    assert_difference 'Planning.count', 0 do
      assert c.create_or_update
    end

    assert_equal 2, c.plannings.length
    assert_empty c.errors

    assert_equal Date.new(2000, 1, 3), p1.reload.date
    assert_equal employees(:pascal).id, p1.employee_id
    assert_equal 25, p1.percent
    assert_not p1.definitive

    assert_equal Date.new(2000, 1, 4), p2.reload.date
    assert_equal employees(:pascal).id, p2.employee_id
    assert_equal 50, p2.percent
    assert p2.definitive

    assert_equal Date.new(2000, 1, 4), p3.reload.date
    assert_equal employees(:mark).id, p3.employee_id
    assert_equal 25, p3.percent
    assert_not p3.definitive

    params = { planning: { percent: 30, definitive: '' },
               items: [
                 { employee_id: employees(:pascal).id.to_s,
                   work_item_id: work_items(:puzzletime).id.to_s,
                   date: '2000-01-03' },
                 { employee_id: employees(:pascal).id.to_s,
                   work_item_id: work_items(:puzzletime).id.to_s,
                   date: '2000-01-04' }
               ] }
    c = Plannings::Creator.new(ActionController::Parameters.new(params))
    assert_difference 'Planning.count', 0 do
      assert c.create_or_update
    end

    assert_equal 2, c.plannings.length
    assert_empty c.errors

    assert_equal Date.new(2000, 1, 3), p1.reload.date
    assert_equal employees(:pascal).id, p1.employee_id
    assert_equal 30, p1.percent
    assert_not p1.definitive

    assert_equal Date.new(2000, 1, 4), p2.reload.date
    assert_equal employees(:pascal).id, p2.employee_id
    assert_equal 30, p2.percent
    assert p2.definitive

    assert_equal Date.new(2000, 1, 4), p3.reload.date
    assert_equal employees(:mark).id, p3.employee_id
    assert_equal 25, p3.percent
    assert_not p3.definitive

    params = { planning: { definitive: true },
               items: [
                 { employee_id: employees(:mark).id.to_s,
                   work_item_id: work_items(:puzzletime).id.to_s,
                   date: '2000-01-04' }
               ] }
    c = Plannings::Creator.new(ActionController::Parameters.new(params))
    assert_difference 'Planning.count', 0 do
      assert c.create_or_update
    end

    assert_equal 1, c.plannings.length
    assert_empty c.errors

    assert_equal Date.new(2000, 1, 3), p1.reload.date
    assert_equal employees(:pascal).id, p1.employee_id
    assert_equal 30, p1.percent
    assert_not p1.definitive

    assert_equal Date.new(2000, 1, 4), p2.reload.date
    assert_equal employees(:pascal).id, p2.employee_id
    assert_equal 30, p2.percent
    assert p2.definitive

    assert_equal Date.new(2000, 1, 4), p3.reload.date
    assert_equal employees(:mark).id, p3.employee_id
    assert_equal 25, p3.percent
    assert p3.definitive
  end

  test '#create_or_update creates and updates plannings' do
    p1 = Planning.create!(employee_id: employees(:mark).id,
                          work_item_id: work_items(:puzzletime).id,
                          date: '2000-01-04',
                          percent: 30,
                          definitive: false)
    params = { planning: { percent: 50, definitive: true },
               items: [
                 { employee_id: employees(:pascal).id.to_s,
                   work_item_id: work_items(:puzzletime).id.to_s,
                   date: '2000-01-03' },
                 { employee_id: employees(:mark).id.to_s,
                   work_item_id: work_items(:puzzletime).id.to_s,
                   date: '2000-01-04' }
               ] }
    c = Plannings::Creator.new(ActionController::Parameters.new(params))
    assert_difference 'Planning.count', 1 do
      assert c.create_or_update
    end

    assert_equal 2, c.plannings.length
    assert_empty c.errors

    assert_equal Date.new(2000, 1, 4), p1.reload.date
    assert_equal employees(:mark).id, p1.employee_id
    assert_equal 50, p1.percent
    assert p1.definitive

    assert_equal Date.new(2000, 1, 3), Planning.last.date
    assert_equal employees(:pascal).id, Planning.last.employee_id
    assert_equal 50, Planning.last.percent
    assert Planning.last.definitive
  end

  test '#create_or_update builds repetitions with new and existing items' do
    p1 = Planning.create!(employee_id: employees(:pascal).id,
                          work_item_id: work_items(:hitobito_demo_app).id,
                          date: '2016-09-27',
                          percent: 30,
                          definitive: false)
    p2 = Planning.create!(employee_id: employees(:pascal).id,
                          work_item_id: work_items(:hitobito_demo_app).id,
                          date: '2016-10-03',
                          percent: 30,
                          definitive: false)
    p3 = Planning.create!(employee_id: employees(:pascal).id,
                          work_item_id: work_items(:hitobito_demo_app).id,
                          date: '2016-10-04',
                          percent: 30,
                          definitive: false)
    items = [
      { employee_id: employees(:pascal).id.to_s, work_item_id: work_items(:hitobito_demo_app).id.to_s,
        date: '2016-09-27' },
      { employee_id: employees(:pascal).id.to_s, work_item_id: work_items(:hitobito_demo_app).id.to_s,
        date: '2016-09-28' },
      { employee_id: employees(:pascal).id.to_s, work_item_id: work_items(:hitobito_demo_app).id.to_s,
        date: '2016-09-29' }
    ]
    c = Plannings::Creator.new(planning: { percent: 50, definitive: false, repeat_until: '201642' }, items:)

    assert_difference('Planning.count', 10) do
      assert c.create_or_update
    end

    assert_equal 12, c.plannings.length
    assert_empty c.errors

    assert_equal 50, p1.reload.percent
    assert_equal 30, p2.reload.percent
    assert_equal 50, p3.reload.percent
  end

  test '#create_or_update builds repetitions without changing attributes' do
    Planning.create!(employee_id: employees(:pascal).id,
                     work_item_id: work_items(:hitobito_demo_app).id,
                     date: '2016-09-27',
                     percent: 30,
                     definitive: false)
    Planning.create!(employee_id: employees(:pascal).id,
                     work_item_id: work_items(:hitobito_demo_app).id,
                     date: '2016-09-28',
                     percent: 30,
                     definitive: false)
    Planning.create!(employee_id: employees(:pascal).id,
                     work_item_id: work_items(:hitobito_demo_app).id,
                     date: '2016-10-03',
                     percent: 50,
                     definitive: true)
    p4 = Planning.create!(employee_id: employees(:pascal).id,
                          work_item_id: work_items(:hitobito_demo_app).id,
                          date: '2016-10-04',
                          percent: 20,
                          definitive: false)
    items = [
      { employee_id: employees(:pascal).id.to_s, work_item_id: work_items(:hitobito_demo_app).id.to_s,
        date: '2016-09-27' },
      { employee_id: employees(:pascal).id.to_s, work_item_id: work_items(:hitobito_demo_app).id.to_s,
        date: '2016-09-28' },
      { employee_id: employees(:pascal).id.to_s, work_item_id: work_items(:hitobito_demo_app).id.to_s,
        date: '2016-09-29' },
      { employee_id: employees(:pascal).id.to_s, work_item_id: work_items(:hitobito_demo_app).id.to_s,
        date: '2016-10-03' }
    ]
    c = Plannings::Creator.new(planning: { percent: '', definitive: '', repeat_until: '201643' }, items:)

    assert_difference('Planning.count', 5) do
      assert c.create_or_update
    end

    assert_equal %w[2016-10-11 2016-10-12 2016-10-17 2016-10-25 2016-10-26],
                 c.plannings.map { |p| p.date.to_s }.sort
    assert_empty c.errors

    assert_equal 20, p4.reload.percent
  end

  test '#create_or_update translates existing plannings ignoring weekends' do
    Planning.create!(employee_id: employees(:pascal).id,
                     work_item_id: work_items(:puzzletime).id,
                     date: '2000-01-03',
                     percent: 50,
                     definitive: true)
    Planning.create!(employee_id: employees(:pascal).id,
                     work_item_id: work_items(:puzzletime).id,
                     date: '2000-01-04',
                     percent: 50,
                     definitive: true)
    Planning.create!(employee_id: employees(:pascal).id,
                     work_item_id: work_items(:puzzletime).id,
                     date: '2000-01-11',
                     percent: 50,
                     definitive: true)

    params = { planning: { translate_by: '6' },
               items: [
                 { employee_id: employees(:pascal).id.to_s,
                   work_item_id: work_items(:puzzletime).id.to_s,
                   date: '2000-01-03' },
                 { employee_id: employees(:pascal).id.to_s,
                   work_item_id: work_items(:puzzletime).id.to_s,
                   date: '2000-01-04' }
               ] }
    c = Plannings::Creator.new(ActionController::Parameters.new(params))
    assert_difference 'Planning.count', -1 do
      assert c.create_or_update
    end

    assert_equal 2, c.plannings.length
    assert_empty c.errors

    plannings = c.plannings.sort_by(&:date)

    p1 = plannings.first
    p2 = plannings.second

    assert_equal Date.new(2000, 1, 11), p1.date
    assert_equal Date.new(2000, 1, 12), p2.date

    params = { planning: { translate_by: '-2' },
               items: [
                 { employee_id: employees(:pascal).id.to_s,
                   work_item_id: work_items(:puzzletime).id.to_s,
                   date: '2000-01-11' },
                 { employee_id: employees(:pascal).id.to_s,
                   work_item_id: work_items(:puzzletime).id.to_s,
                   date: '2000-01-12' }
               ] }
    c = Plannings::Creator.new(ActionController::Parameters.new(params))
    assert_difference 'Planning.count', 0 do
      assert c.create_or_update
    end

    assert_equal 2, c.plannings.length
    assert_empty c.errors

    p1 = c.plannings.first
    p2 = c.plannings.second

    assert_equal Date.new(2000, 1, 7), p1.date
    assert_equal Date.new(2000, 1, 10), p2.date
  end

  test '#form_valid? with no planning params returns false and sets errors' do
    [{}, { plannings: nil }, { plannings: {} }].each do |p|
      c = Plannings::Creator.new(p)

      assert_not_predicate c, :form_valid?, "Expected to be invalid for #{p}"
      assert_includes c.errors, 'Bitte füllen Sie das Formular aus',
                      "Expected to contain error for #{p}"
    end
  end

  test '#form_valid? for new items with missing percent/definitive returns false and sets errors' do
    [{ percent: '', definitive: true, repeat_until: '2016 42' },
     { definitive: true, repeat_until: '2016 42' }].each do |p|
      c = Plannings::Creator.new({ planning: p, items: items_to_create })

      assert_not_predicate c, :form_valid?, "Expected to be invalid for #{p}"
      assert_includes c.errors, 'Prozent müssen angegeben werden, um neue Planungen zu erstellen',
                      "Expected to contain error for #{p}"
    end

    [{ percent: '50', definitive: '', repeat_until: '2016 42' },
     { percent: '50', repeat_until: '2016 42' }].each do |p|
      c = Plannings::Creator.new({ planning: p, items: items_to_create })

      assert_not_predicate c, :form_valid?, "Expected to be invalid for #{p}"
      assert_includes c.errors, 'Status muss angegeben werden, um neue Planungen zu erstellen',
                      "Expected to contain error for #{p}"
    end
  end

  test '#form_valid? for new items with percent/definitive or repeat only returns true' do
    [{ percent: 50, definitive: true, repeat_until: '2016 42' },
     { percent: 50, definitive: false, repeat_until: '2016 42' },
     { repeat_until: '2016 42' }].each do |p|
      c = Plannings::Creator.new({ planning: p, items: items_to_create })

      assert_predicate c, :form_valid?, "Expected to be valid for #{p}"
      assert_not c.errors.include?('Prozent müssen angegeben werden, um neue Planungen zu erstellen'),
                 "Expected to not contain error for #{p}"
      assert_not c.errors.include?('Status muss angegeben werden, um neue Planungen zu erstellen'),
                 "Expected to not contain error for #{p}"
    end
  end

  test '#form_valid? for work items without accounting post returns false' do
    params = { planning: { percent: 50, definitive: true },
               items: [
                 { employee_id: employees(:pascal).id.to_s,
                   work_item_id: work_items(:puzzle).id.to_s,
                   date: '2000-01-03' },
                 { employee_id: employees(:pascal).id.to_s,
                   work_item_id: work_items(:puzzletime).id.to_s,
                   date: '2000-01-04' }
               ] }
    c = Plannings::Creator.new(params)

    assert_not_predicate c, :form_valid?
    assert_includes c.errors, 'Nur Positionen mit Buchungsposition sind möglich'
  end

  test '#form_valid? with percent > 0 returns true' do
    %w[1 100].each do |percent|
      c = Plannings::Creator.new({ planning: { percent: } })

      assert_predicate c, :form_valid?, "Expected to be valid for #{percent}"
      assert_not c.errors.include?('Prozent müssen grösser als 0 sein'),
                 "Expected to not contain error for #{p}"
    end
  end

  test '#form_valid? with percent <= 0 returns false and sets errors' do
    ['0', '-1'].each do |percent|
      c = Plannings::Creator.new({ planning: { percent: } })

      assert_not_predicate c, :form_valid?, "Expected to be invalid for #{percent}"
      assert_includes c.errors, 'Prozent müssen grösser als 0 sein',
                      "Expected to contain error for #{p}"
    end
  end

  test '#form_valid? with valid repeat_until returns true' do
    ['201642', '2016 42'].each do |repeat_until|
      c = Plannings::Creator.new({ planning: { repeat_until: } })

      assert_predicate c, :form_valid?, "Expected to be valid for #{repeat_until}"
      assert_not c.errors.include?('Wiederholungsdatum ist ungültig'),
                 "Expected to not contain error for #{p}"
    end
  end

  test '#form_valid? with invalid repeat_until returns false and sets errors' do
    %w[foo 200099].each do |repeat_until|
      c = Plannings::Creator.new({ planning: { repeat_until: } })

      assert_not_predicate c, :form_valid?, "Expected to be invalid for #{repeat_until}"
      assert_includes c.errors, 'Wiederholungsdatum ist ungültig',
                      "Expected to contain error for #{p}"
    end
  end

  test '#repeat_only? returns true if :repeat_until is set and other values are not present' do
    c = Plannings::Creator.new({ planning: { repeat_until: '2016 42' } })

    assert_predicate c, :repeat_only?
  end

  test '#repeat_only? returns false if :repeat_until is not set or other values are present' do
    [{},
     { percent: 50, definitive: true },
     { percent: 50, definitive: false },
     { percent: 50, definitive: true, repeat_until: '' },
     { percent: 50, definitive: false, repeat_until: '' },
     { definitive: true, repeat_until: '2016 42' },
     { percent: '', definitive: false, repeat_until: '2016 42' },
     { percent: 50, repeat_until: '2016 42' },
     { percent: 50, definitive: '', repeat_until: '2016 42' }].each do |p|
      c = Plannings::Creator.new({ planning: p })

      assert_not_predicate c, :repeat_only?, "Expected to be false for #{p}"
    end
  end

  private

  def items_to_create
    [{ employee_id: employees(:pascal).id.to_s,
       work_item_id: work_items(:puzzletime).id.to_s,
       date: '2000-01-03' }]
  end
end
