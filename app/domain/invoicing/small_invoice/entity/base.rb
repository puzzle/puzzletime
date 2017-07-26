# encoding: utf-8

#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.


module Invoicing
  module SmallInvoice
    module Entity
      class Base
        attr_reader :entry

        def initialize(entry)
          @entry = entry
        end

        def ==(other)
          self_hash = stringify(to_hash)
          other_hash = stringify(other.to_hash)
          keys = self_hash.keys & other_hash.keys
          keys.all? { |key| self_hash[key] == other_hash[key] }
        end

        private

        def constant(key)
          Settings.small_invoice.constants.send(key)
        end

        def bool_constant(key)
          constant(key) ? 1 : 0
        end

        def with_id(hash)
          hash.tap { hash[:id] = entry.invoicing_key if entry.invoicing_key? }
        end

        def stringify(hash)
          hash.each_with_object({}) do |(key, value), memo|
            memo[key.to_s] = value.to_s.strip
          end
        end
      end
    end
  end
end
