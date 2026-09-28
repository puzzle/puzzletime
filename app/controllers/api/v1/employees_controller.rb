# frozen_string_literal: true

#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

module Api
  module V1
    class EmployeesController < JsonapiController
      include Scopable

      # associations touched by EmployeeSerializer's attribute blocks
      EAGER_LOAD_ASSOCIATIONS = {
        department: {},
        employments: {},
        current_employment: { employment_roles_employments: %i[employment_role employment_role_level] }
      }.freeze

      self.filter_attrs = %i[email ldapname keycloakopenid]

      annotate_param :index,
                     :scope,
                     type: 'string',
                     enum: ['current'],
                     description: <<~DESC
                       The query scope:
                       * current - only employees with a current employment
                     DESC

      annotate_param :index,
                     'filter[email]',
                     type: 'string',
                     description: 'Return only the employee with this email address.'

      annotate_param :index,
                     'filter[ldapname]',
                     type: 'string',
                     description: 'Return only the employee with this LDAP name.'

      annotate_param :index,
                     'filter[keycloakopenid]',
                     type: 'string',
                     description: 'Return only the employee linked to this Keycloak OpenID uid.'

      def list_entries
        entries = super.includes(EAGER_LOAD_ASSOCIATIONS)
        scoped(entries, :current)
      end

      private

      # The keycloakopenid uid lives on the associated authentications, not on
      # the employees table, so it needs a custom join-based filter.
      def filter_by_param_keycloakopenid(entries, _attribute, value)
        entries.joins(:authentications)
               .where(authentications: { provider: :keycloakopenid, uid: value })
      end
    end
  end
end
