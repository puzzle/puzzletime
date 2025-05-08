# frozen_string_literal: true

#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

# {{{
# == Schema Information
#
# Table name: order_statuses
#
#  id       :integer          not null, primary key
#  closed   :boolean          default(FALSE), not null
#  default  :boolean          default(FALSE), not null
#  name     :string           not null
#  position :integer          not null
#  style    :string
#
# Indexes
#
#  index_order_statuses_on_name      (name) UNIQUE
#  index_order_statuses_on_position  (position)
#
# }}}

class OrderStatus < ApplicationRecord
  STYLES = %w[default success info warning danger].freeze

  include Closable

  has_many :orders, foreign_key: :status_id

  validates_by_schema
  validates :name, :position, uniqueness: true
  validates :style, inclusion: STYLES

  protect_if :orders, 'Der Eintrag kann nicht gelöscht werden, da ihm noch Aufträge zugeordnet sind'

  scope :list, -> { order(:position) }
  scope :defaults, -> { list.where(default: true) }
  scope :open, -> { where(closed: false) }

  def to_s
    name
  end

  def propagate_closed!
    orders.includes(:status).find_each(&:propagate_closed!)
  end
end
