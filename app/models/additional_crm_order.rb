#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.


# == Schema Information
#
# Table name: additional_crm_orders
#
#  id       :integer          not null, primary key
#  order_id :integer          not null
#  crm_key  :string           not null
#  name     :string
#

class AdditionalCrmOrder < ActiveRecord::Base

  belongs_to :order

  validates_by_schema

  scope :list, -> { order(:name) }

  def to_s
    name
  end

end
