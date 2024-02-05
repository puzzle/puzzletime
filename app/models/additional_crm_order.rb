# frozen_string_literal: true

#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

# == Schema Information
#
# Table name: additional_crm_orders
#
#  id       :bigint(8)        not null, primary key
#  order_id :bigint(8)        not null
#  crm_key  :string           not null
#  name     :string
#

class AdditionalCrmOrder < ApplicationRecord
  belongs_to :order

  validates_by_schema

  after_save :sync_name, if: :saved_change_to_crm_key?

  scope :list, -> { order(:name) }

  def to_s
    name
  end

  private

  def sync_name
    return unless Crm.instance

    Crm.instance.delay.sync_additional_order(self)
  end
end
