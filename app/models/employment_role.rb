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

class EmploymentRole < ActiveRecord::Base
  belongs_to :employment_role_category
  has_many :employment_roles_employments, dependent: :restrict_with_exception

  validates :name, uniqueness: { case_sensitive: false }

  def to_s
    name
  end
end
