# frozen_string_literal: true

#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

require 'test_helper'
require_relative 'eval_test_helper'

module Evaluations
  class AbsencesEvalTest < ActiveSupport::TestCase
    include EvalTestHelper

    def setup
      super
      @evaluation = Evaluations::AbsencesEval.new
      @times = [@period_month].collect { |p| @evaluation.sum_times_grouped(p) }
    end

    def test_absences
      create_absences

      assert_predicate @evaluation, :absences?
      assert_not @evaluation.for?(employees(:pascal))
      assert @evaluation.total_details

      divisions = @evaluation.divisions(@period_month, @times)

      assert_equal 3, divisions.size

      assert_sum_times 0, 8, 9, 9, employees(:mark)
      assert_sum_times 0, 0, 13, 13, employees(:lucien)
      assert_sum_times 0, 4, 18, 18, employees(:pascal)

      assert_empty(@evaluation.sum_times_grouped(@period_day))
      assert_equal({ employees(:mark).id => 8.0, employees(:pascal).id => 4.0 },
                   @evaluation.sum_times_grouped(@period_week))
      assert_equal({ employees(:mark).id => 9.0, employees(:lucien).id => 13.0, employees(:pascal).id => 18.0 },
                   @evaluation.sum_times_grouped(@period_month))

      assert_sum_total_times 0.0, 12.0, 40.0, 40.0
    end

    def test_absences_detail_mark
      @evaluation.set_division_id employees(:mark).id

      assert_sum_times 0, 8, 8, 8
      assert_count_times 0, 1, 1, 1
    end

    def test_absences_detail_lucien
      @evaluation.set_division_id employees(:lucien).id

      assert_sum_times 0, 0, 12, 12
      assert_count_times 0, 0, 1, 1
    end

    def test_absences_detail_pascal
      @evaluation.set_division_id employees(:pascal).id

      assert_sum_times 0, 4, 17, 17
      assert_count_times 0, 1, 2, 2
    end

    def create_absences
      %i[mark lucien pascal].each do |e|
        employees(e).employments.create!(start_date: @period_month.start_date,
                                         percent: 60,
                                         employment_roles_employments: [Fabricate.build(:employment_roles_employment)])
        Fabricate(:absencetime, employee: employees(e), work_date: @period_month.start_date, hours: 1)
      end
    end
  end
end
