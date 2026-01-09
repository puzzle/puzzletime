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
  end
end
