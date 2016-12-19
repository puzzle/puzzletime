require 'test_helper'

class DepartmentOrdersEvalTest < ActiveSupport::TestCase
  setup do
    @eval = DepartmentOrdersEval.new(department.id)
  end

  test 'adds completed supplement' do
    supplement = @eval.division_supplement(employees(:mark))
    assert_equal 2, supplement.length
    assert_equal :order_completed, supplement.first.first
  end

  private

  def department
    departments(:devone)
  end
end
