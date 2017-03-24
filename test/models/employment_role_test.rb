# == Schema Information
#
# Table name: employment_roles
#
#  id                          :integer          not null, primary key
#  name                        :string           not null
#  billable                    :boolean          not null
#  level                       :boolean          not null
#  employment_role_category_id :integer
#

require 'test_helper'

class EmploymentRoleTest < ActiveSupport::TestCase
  test 'string representation matches name' do
    assert_equal employment_roles(:software_engineer).to_s, 'Software Engineer'
  end
end
