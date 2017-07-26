# encoding: utf-8

#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.


# == Schema Information
#
# Table name: order_targets
#
#  id              :integer          not null, primary key
#  order_id        :integer          not null
#  target_scope_id :integer          not null
#  rating          :string           default("green"), not null
#  comment         :text
#  created_at      :datetime
#  updated_at      :datetime
#

class OrderTarget < ActiveRecord::Base

  RATINGS = %w(green orange red).freeze

  belongs_to :order
  belongs_to :target_scope

  validates_by_schema
  validates :rating, inclusion: RATINGS
  validates :comment, presence: { if: :target_critical? }
  validates :target_scope_id, uniqueness: { scope: :order_id }

  scope :list, lambda {
    includes(:target_scope).
      references(:target_scope).
      order('target_scopes.position')
  }

  def target_critical?
    rating != RATINGS.first
  end

end
