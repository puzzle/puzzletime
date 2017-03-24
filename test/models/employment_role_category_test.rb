# encoding: utf-8

# == Schema Information
#
# Table name: employment_role_categories
#
#  id   :integer          not null, primary key
#  name :string           not null
#

require 'test_helper'

class EmploymentRoleCategoryTest < ActiveSupport::TestCase
  test 'string representation matches name' do
    assert_equal employment_role_categories(:management).to_s, 'Management'
  end
end
