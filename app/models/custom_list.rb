# frozen_string_literal: true

#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

# == Schema Information
#
# Table name: custom_lists
#
#  id          :integer          not null, primary key
#  name        :string           not null
#  employee_id :integer
#  item_type   :string           not null
#  item_ids    :integer          not null, is an Array
#

class CustomList < ApplicationRecord
  belongs_to :employee, optional: true

  validates_by_schema except: :item_ids

  scope :list, -> { order(:name) }

  attr_readonly :item_type

  def to_s
    name
  end

  def items
    item_type.constantize.where(id: item_ids)
  end
end
