# frozen_string_literal: true

#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

# == Schema Information
#
# Table name: target_scopes
#
#  id                        :integer          not null, primary key
#  name                      :string           not null
#  icon                      :string
#  position                  :integer          not null
#  rating_green_description  :string
#  rating_orange_description :string
#  rating_red_description    :string
#

class TargetScope < ApplicationRecord
  has_many :order_targets, dependent: :destroy

  validates_by_schema
  validates :name, :position, :icon, uniqueness: true
  validates :icon, presence: true

  after_create :create_order_targets

  scope :list, -> { order(:position) }

  def to_s
    name
  end

  private

  def create_order_targets
    Order.find_each do |o|
      o.targets.create!(target_scope: self, rating: OrderTarget::RATINGS.first)
    end
  end
end
