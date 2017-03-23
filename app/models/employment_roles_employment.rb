# encoding: utf-8
# == Schema Information
#
# Table name: employment_roles_employments
#
#  employment_id            :integer          not null
#  employment_role_id       :integer          not null
#  percent                  :decimal(5, 2)    not null
#  employment_role_level_id :integer
#

class EmploymentRolesEmployment < ActiveRecord::Base
  belongs_to :employment
  belongs_to :employment_role
  belongs_to :employment_role_level

  validates :percent, inclusion: 0..200
  validate :valid_level

  private

  def valid_level
    if employment_role.level? && !employment_role_level_id
      errors.add(:employment_role_level_id,
                 "Die Rolle '#{employment_role.name}' erfordert eine Stufe.")
    elsif !employment_role.level? && employment_role_level_id
      errors.add(:employment_role_level_id,
                 "Die Rolle '#{employment_role.name}' hat keine Stufen.")
    end
  end
end
