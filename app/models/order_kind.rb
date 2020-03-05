#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

# == Schema Information
#
# Table name: order_kinds
#
#  id   :integer          not null, primary key
#  name :string           not null
#

class OrderKind < ActiveRecord::Base
  has_many :orders, foreign_key: :kind_id

  validates_by_schema
  validates :name, uniqueness: true

  protect_if :orders, 'Der Eintrag kann nicht gelöscht werden, da ihm noch Aufträge zugeordnet sind'

  scope :list, -> { order(:name) }

  def to_s
    name
  end
end
