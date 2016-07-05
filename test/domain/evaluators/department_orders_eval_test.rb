require 'test_helper'

class DepartmentOrdersEvalTest < ActiveSupport::TestCase
  setup do
    @eval = DepartmentOrdersEval.new(department.id)
  end

  test 'adds month end supplement if last month and has ability' do
    supplement = @eval.division_supplement(employees(:mark), Period.parse('-1m'))
    assert_equal 1, supplement.length
    assert_equal :order_month_end_completions, supplement.first.first
  end

  test 'does not add month end supplement if before last month but has ability' do
    supplement = @eval.division_supplement(employees(:mark), Period.parse('-2m'))
    assert_equal [], supplement
  end

  test 'does not add month end supplement if coming month but has ability' do
    supplement = @eval.division_supplement(employees(:mark), Period.parse('+1m'))
    assert_equal [], supplement
  end

  test 'does not add month end supplement if last month but has no ability' do
    supplement = @eval.division_supplement(employees(:various_pedro), Period.parse('-1m'))
    assert_equal [], supplement
  end

  private

  def department
    departments(:devone)
  end
end
