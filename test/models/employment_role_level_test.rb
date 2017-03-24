# encoding: utf-8

# == Schema Information
#
# Table name: employment_role_levels
#
#  id   :integer          not null, primary key
#  name :string           not null
#

require 'test_helper'

class EmploymentRoleLevelTest < ActiveSupport::TestCase
  test 'string representation matches name' do
    assert_equal employment_role_levels(:senior).to_s, 'Senior'
  end
end
