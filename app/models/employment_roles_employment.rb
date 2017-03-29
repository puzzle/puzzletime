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

  scope :list, -> { order('percent DESC') }

  def to_s
    level = if employment_role_level_id
              " #{employment_role_level}"
            else
              ''
            end

    "#{percent.round}% #{employment_role}#{level}"
  end

  private

  def valid_level
    if employment_role.level? && !employment_role_level_id
      errors.add(:employment_role_level_id,
                 "Die Funktion '#{employment_role.name}' erfordert eine Stufe.")
    elsif !employment_role.level? && employment_role_level_id
      errors.add(:employment_role_level_id,
                 "Die Funktion '#{employment_role.name}' hat keine Stufen.")
    end
  end
end
