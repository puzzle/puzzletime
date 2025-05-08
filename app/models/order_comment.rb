# frozen_string_literal: true

#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

# {{{
# == Schema Information
#
# Table name: order_comments
#
#  id         :integer          not null, primary key
#  text       :text             not null
#  created_at :datetime
#  updated_at :datetime
#  creator_id :integer
#  order_id   :integer          not null
#  updater_id :integer
#
# Indexes
#
#  index_order_comments_on_order_id  (order_id)
#
# }}}

class OrderComment < ApplicationRecord
  ### ASSOCIATIONS

  belongs_to :order
  belongs_to :creator, class_name: 'Employee'
  belongs_to :updater, class_name: 'Employee'

  ### VALIDATIONS

  validates_by_schema

  ### SCOPES

  scope :list, -> { includes(:creator).order('updated_at DESC') }

  ### INSTANCE METHODS

  def to_s
    "#{creator}: #{text.truncate(20)}"
  end
end
