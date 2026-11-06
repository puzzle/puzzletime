# frozen_string_literal: true

require 'test_helper'

module Forms
  class MultiOrdertimeTest < ActiveSupport::TestCase
    test 'max_allowed_repetitions logic' do
      # 05.01.2025 (Monday) -> 5
      form_mo = Forms::MultiOrdertime.new(work_date: Date.parse('2026-01-05'))

      assert_equal 5, form_mo.send(:max_allowed_repetitions)

      # 08.01.2025 (Thursday) -> 2
      form_th = Forms::MultiOrdertime.new(work_date: Date.parse('2026-01-08'))

      assert_equal 2, form_th.send(:max_allowed_repetitions)

      # 09.01.2025 (Friday) -> 1
      form_fr = Forms::MultiOrdertime.new(work_date: Date.parse('2026-01-09'))

      assert_equal 1, form_fr.send(:max_allowed_repetitions)

      # 10.01.2025 (Saturday) -> 1
      form_sa = Forms::MultiOrdertime.new(work_date: Date.parse('2026-01-10'))

      assert_equal 1, form_sa.send(:max_allowed_repetitions)

      # 11.01.2025 (Sunday) -> 1
      form_su = Forms::MultiOrdertime.new(work_date: Date.parse('2026-01-11'))

      assert_equal 1, form_su.send(:max_allowed_repetitions)
    end

    test 'validation of repetitions' do
      form = Forms::MultiOrdertime.new(work_date: Date.parse('2026-01-07'), repetitions: 4)

      assert_not_predicate form, :valid?
      assert_includes form.errors[:repetitions], 'muss kleiner oder gleich 3 sein'

      form = Forms::MultiOrdertime.new(work_date: Date.parse('2026-01-07'), repetitions: 3)

      assert_predicate form, :valid?
    end

    test 'dates leave out holidays without extending the period' do
      Holiday.create!(holiday_date: Date.parse('2026-01-07'), musthours_day: 0)
      Holiday.clear_cache

      assert_equal %w[2026-01-05 2026-01-06 2026-01-08].map { |day| Date.parse(day) },
                   multi_form(work_date: '2026-01-05', repetitions: 4).dates
    end

    test 'dates keep half holidays' do
      Holiday.create!(holiday_date: Date.parse('2026-01-06'), musthours_day: 4)
      Holiday.clear_cache

      assert_includes multi_form(work_date: '2026-01-05', repetitions: 2).dates, Date.parse('2026-01-06')
    end

    test 'dates keep the chosen start date even on a holiday' do
      Holiday.create!(holiday_date: Date.parse('2026-01-05'), musthours_day: 0)
      Holiday.clear_cache

      assert_includes multi_form(work_date: '2026-01-05', repetitions: 2).dates, Date.parse('2026-01-05')
    end

    private

    def multi_form(**attrs)
      Forms::MultiOrdertime.new(**attrs, employee: employees(:long_time_john))
    end
  end
end
