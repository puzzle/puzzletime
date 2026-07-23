# frozen_string_literal: true

#  Copyright (c) 2006-2026, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

module Api
  module V1
    class OrdersController < JsonapiController
      self.filter_attrs = %i[email ldapname keycloakopenid]

      annotate_param :index,
                     'filter[email]',
                     type: 'string',
                     description: 'Return only orders where the employee with this email address ' \
                                  'is responsible or a team member.'

      annotate_param :index,
                     'filter[ldapname]',
                     type: 'string',
                     description: 'Return only orders where the employee with this LDAP name ' \
                                  'is responsible or a team member.'

      annotate_param :index,
                     'filter[keycloakopenid]',
                     type: 'string',
                     description: 'Return only orders where the employee linked to this Keycloak ' \
                                  'OpenID uid is responsible or a team member.'

      private

      def list_entries
        super.includes(%i[kind status department contract billing_address invoices])
      end

      def filter_by_param_ldapname(entries, _attribute, value)
        relevant_entries(entries, Employee.find_by(ldapname: value))
      end

      def filter_by_param_email(entries, _attribute, value)
        relevant_entries(entries, Employee.find_by(email: value))
      end

      def filter_by_param_keycloakopenid(entries, _attribute, value)
        relevant_entries(
          entries,
          Authentication.find_by(provider: :keycloakopenid, uid: value).employee
        )
      end

      def relevant_entries(entries, employee)
        team_order_ids = OrderTeamMember.where(employee_id: employee).select(:order_id)
        entries.where(responsible: employee)
               .or(entries.where(id: team_order_ids))
      end
    end
  end
end
