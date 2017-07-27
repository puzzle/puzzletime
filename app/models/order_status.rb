#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.


# == Schema Information
#
# Table name: order_statuses
#
#  id       :integer          not null, primary key
#  name     :string           not null
#  style    :string
#  closed   :boolean          default(FALSE), not null
#  position :integer          not null
#  default  :boolean          default(FALSE), not null
#

class OrderStatus < ActiveRecord::Base
  STYLES = %w(default success info warning danger).freeze

  include Closable

  has_many :orders, foreign_key: :status_id

  validates_by_schema
  validates :name, :position, uniqueness: true
  validates :style, inclusion: STYLES

  protect_if :orders, 'Der Eintrag kann nicht gelöscht werden, da ihm noch Aufträge zugeordnet sind'

  scope :list, -> { order(:position) }
  scope :defaults, -> { list.where(default: true) }


  def to_s
    name
  end

  def propagate_closed!
    orders.includes(:status).find_each(&:propagate_closed!)
  end
end
