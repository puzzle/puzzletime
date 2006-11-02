require File.dirname(__FILE__) + '/../test_helper'

class EmployeeTest < Test::Unit::TestCase
  fixtures :employees
  
  def setup
    @employee = Employee.find(1)
  end

  # Replace this with your real tests.
  def test_create
    assert_kind_of Employee, @employee
    assert_equal 1, @employee.id
    assert_equal "Dolores", @employee.lastname
    assert_equal "Maria", @employee.firstname
    assert_equal "ggg", @employee.shortname
    assert_equal "Yaataw", @employee.passwd
    assert_equal "bla@bla.ch", @employee.email
    assert_equal true, @employee.management
    assert_equal "9393", @employee.phone
  end
end
