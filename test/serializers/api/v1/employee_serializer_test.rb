# frozen_string_literal: true

#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

require 'test_helper'

module Api
  module V1
    class EmployeeSerializerTest < ActiveSupport::TestCase
      test '#serializable_hash' do
        employee = employees(:long_time_john)
        employee.city = 'Eldoria'
        employee.birthday = Date.new(1111, 2, 3)

        serialized = Api::V1::EmployeeSerializer.new(employee).serializable_hash

        expected = { data: { id: '5',
                             type: :employee,
                             attributes: { shortname: 'JN',
                                           firstname: 'John',
                                           lastname: 'Neverends',
                                           email: 'jn@bla.ch',
                                           marital_status: 'single',
                                           nationalities: %w[CH UK],
                                           graduation: 'Klubschule',
                                           city: 'Eldoria',
                                           birthday: employee.birthday,
                                           full_name: 'Neverends John',
                                           is_employed: true,
                                           department_shortname: 'D1',
                                           employment_roles: [{ name: 'Software Developer', percent: 90.0 }] } } }

        assert_equal expected, serialized
      end
    end
  end
end
