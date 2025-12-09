# frozen_string_literal: true

#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

class Order
  class Copier
    attr_reader :source

    def initialize(source)
      @source = source
    end

    # Copies an order together with everything that is edited in the order form.
    def copy
      return @copy if defined?(@copy)

      @copy = source.dup
      @copy.work_item = source.work_item.dup
      @copy.work_item.parent_id = source.work_item.parent_id
      @copy.order_contacts = source.order_contacts.collect(&:dup)
      @copy.order_team_members = source.order_team_members.collect(&:dup)
      @copy.crm_key = nil
      @copy.status_id = nil
      @copy.set_default_status_id
      @copy
    end

    # Copies all order associations not edited in the order form.
    def copy_associations(target)
      target.work_item.order = target
      target.contract = source.contract.try(:dup)

      copy_work_item_children(source.work_item, target.work_item)
    end

    private

    def copy_work_item_children(source, target)
      copy_accounting_post(source.accounting_post, target)

      source.children.each do |child|
        copy = child.dup
        copy.parent = target
        target.children << copy

        copy_work_item_children(child, copy)
      end
    end

    def copy_accounting_post(source, work_item)
      return if source.nil?

      copy = source.dup
      copy.work_item = work_item
      copy.closed = false
      work_item.accounting_post = copy

      copy
    end
  end
end
