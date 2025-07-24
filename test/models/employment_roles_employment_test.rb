# frozen_string_literal: true

#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

# {{{
# == Schema Information
#
# Table name: employment_roles_employments
#
#  id                       :integer          not null, primary key
#  percent                  :decimal(5, 2)    not null
#  employment_id            :integer          not null
#  employment_role_id       :integer          not null
#  employment_role_level_id :integer
#
# Indexes
#
#  index_unique_employment_employment_role  (employment_id,employment_role_id) UNIQUE
#
# }}}

require 'test_helper'

class EmploymentRolesEmploymentTest < ActiveSupport::TestCase
  test 'string representation matches name' do
    e = EmploymentRolesEmployment.create!(
      employment: employments(:long_time),
      employment_role: employment_roles(:software_engineer),
      employment_role_level: employment_role_levels(:senior),
      percent: 90
    )

    assert_equal 'Software Engineer Senior 90%', e.to_s
  end

  test 'string representation does not round percent' do
    e = EmploymentRolesEmployment.create!(
      employment: employments(:long_time),
      employment_role: employment_roles(:software_engineer),
      employment_role_level: employment_role_levels(:senior),
      percent: 90.25
    )

    assert_equal 'Software Engineer Senior 90.25%', e.to_s
  end

  test 'role with required level validation' do
    err = assert_raises ActiveRecord::RecordInvalid do
      EmploymentRolesEmployment.create!(employment: employments(:long_time),
                                        employment_role: employment_roles(:software_engineer),
                                        percent: 90)
    end

    assert_match(/Die Funktion 'Software Engineer' erfordert eine Stufe\./,
                 err.message)

    assert_nothing_raised do
      EmploymentRolesEmployment.create!(employment: employments(:long_time),
                                        employment_role: employment_roles(:software_engineer),
                                        employment_role_level: employment_role_levels(:senior),
                                        percent: 90)
    end
  end

  test 'role without required level validation' do
    err = assert_raises ActiveRecord::RecordInvalid do
      EmploymentRolesEmployment.create!(employment: employments(:long_time),
                                        employment_role: employment_roles(:technical_board),
                                        employment_role_level: employment_role_levels(:senior),
                                        percent: 90)
    end

    assert_match(/Die Funktion 'Member of the Technical Board' hat keine Stufen\./,
                 err.message)

    assert_nothing_raised do
      EmploymentRolesEmployment.create!(employment: employments(:long_time),
                                        employment_role: employment_roles(:technical_board),
                                        percent: 90)
    end
  end

  test 'role percent validation' do
    err = assert_raises ActiveRecord::RecordInvalid do
      EmploymentRolesEmployment.create!(employment: employments(:long_time),
                                        employment_role: employment_roles(:technical_board),
                                        percent: -1)
    end

    assert_match(/Pensum ist kein gültiger Wert/, err.message)

    err = assert_raises ActiveRecord::RecordInvalid do
      EmploymentRolesEmployment.create!(employment: employments(:long_time),
                                        employment_role: employment_roles(:technical_board),
                                        percent: 201)
    end

    assert_match(/Pensum ist kein gültiger Wert/, err.message)
  end
end
