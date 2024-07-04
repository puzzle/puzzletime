# frozen_string_literal: true

#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

module Api
  module V1
    class EmployeeSerializer < ApiSerializer
      attributes  :shortname,
                  :firstname,
                  :lastname,
                  :email,
                  :marital_status,
                  :nationalities,
                  :graduation,
                  :city,
                  :birthday,
                  :nationalities

      attribute :full_name do |employee|
        employee.to_s
      end

      attribute :is_employed do |_employee|
        !e.current_employment.nil?
      end

      attribute :department_shortname do |employee|
        employee.department&.shortname
      end

      attribute :employment_roles do |employee|
        Array.wrap(employee.current_employment&.employment_roles_employments).map do |employment_roles_employment|
          {
            name: employment_roles_employment.employment_role.name,
            percent: employment_roles_employment.percent.to_f
          }
        end
      end

      # attribute annotations for the generated api docs

      annotate_attributes :shortname, :firstname, :lastname, :email, :graduation, :department_shortname,
                          type: :string

      annotate_attribute :marital_status,
                         type: :string,
                         enum: Employee.marital_statuses.keys

      annotate_attribute :nationalities,
                         description: 'Two letter country codes as specified in ISO 3166',
                         type: :array,
                         items: {
                           type: :string
                         }

      annotate_attribute :employment_roles,
                         type: :object,
                         properties: {
                           name: {
                             type: :string,
                             description: 'The role name'
                           },
                           percent: {
                             type: :number,
                             format: :float
                           }
                         }
    end
  end
end
