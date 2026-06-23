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
                     description: 'Return only the employee with this email address.'

      annotate_param :index,
                     'filter[ldapname]',
                     type: 'string',
                     description: 'Return only the employee with this LDAP name.'

      annotate_param :index,
                     'filter[keycloakopenid]',
                     type: 'string',
                     description: 'Return only the employee linked to this Keycloak OpenID uid.'

      private

      def with_joined(entries)
        filtered = yield entries.joins(team_members: :authentications)

        # Remove unnecessary joins again
        entries.where(id: filtered)
      end

      def filter_by_param_ldapname(entries, _attribute, value)
        with_joined(entries) do |joined|
          joined.where(team_members: { ldapname: value })
        end
      end

      def filter_by_param_email(entries, _attribute, value)
        with_joined(entries) do |joined|
          joined.where(team_members: { email: value })
        end
      end

      # The keycloakopenid uid lives on the associated authentications
      def filter_by_param_keycloakopenid(entries, _attribute, value)
        with_joined(entries) do |joined|
          joined.where(authentications: { provider: :keycloakopenid, uid: value })
        end
      end
    end
  end
end
