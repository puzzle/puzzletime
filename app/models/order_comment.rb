# frozen_string_literal: true

#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

# == Schema Information
#
# Table name: order_comments
#
#  id         :integer          not null, primary key
#  order_id   :integer          not null
#  text       :text             not null
#  creator_id :integer
#  updater_id :integer
#  created_at :datetime
#  updated_at :datetime
#

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
