# frozen_string_literal: true

#  Copyright (c) 2006-2026, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

# Adds support for the JSON:API `filter` query parameter family.
#
# Declare the filterable attributes in your subclassing controller using the
# class attribute +filter_attrs+:
#
#   self.filter_attrs = %i[email ldapname]
#
# Each declared attribute may then be filtered with an exact match, e.g.
# `GET /api/v1/employees?filter[ldapname]=jneverends`. Multiple filters are
# combined with AND.
#
# By default an attribute is matched against the column of the same name. To
# implement custom filter logic for a specific attribute, define a
# +filter_by_param_<attribute>+ method:
#
#   def filter_by_param_keycloakopenid(entries, _attribute, value)
#     entries.joins(:authentications)
#            .where(authentications: { provider: :keycloakopenid, uid: value })
#   end
module JsonapiFilterable
  extend ActiveSupport::Concern

  included do
    class_attribute :filter_attrs
    self.filter_attrs = []

    prepend Prepends
  end

  # Prepended methods for filtering.
  module Prepends
    private

    # Enhance the list entries with the requested filters.
    def list_entries
      filter_params.reduce(super) do |entries, (attribute, value)|
        method = "filter_by_param_#{attribute}"
        if respond_to?(method, true)
          send(method, entries, attribute, value)
        else
          filter_by_param(entries, attribute, value)
        end
      end
    end

    # The permitted `filter[...]` parameters as a symbol-keyed hash.
    def filter_params
      return {} if filter_attrs.blank?

      params.fetch(:filter, {}).permit(*filter_attrs).to_h.symbolize_keys
    end
  end

  private

  # Default filter implementation: exact match on the attribute's own column.
  # Override with +filter_by_param_<attribute>+ for custom logic.
  def filter_by_param(entries, attribute, value)
    entries.where(attribute => value)
  end
end
