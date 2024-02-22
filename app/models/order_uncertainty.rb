# frozen_string_literal: true

#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

# == Schema Information
#
# Table name: order_uncertainties
#
#  id          :integer          not null, primary key
#  order_id    :integer          not null
#  type        :string           not null
#  name        :string           not null
#  probability :integer          default("improbable"), not null
#  impact      :integer          default("none"), not null
#  measure     :text
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#

class OrderUncertainty < ApplicationRecord
  MEDIUM_THRESHOLD = 3
  HIGH_THRESHOLD = 8

  belongs_to :order

  enum probability: {
    improbable: 1,
    low: 2,
    medium: 3,
    high: 4
  }, _suffix: true

  enum impact: {
    none: 1,
    low: 2,
    medium: 3,
    high: 4
  }, _suffix: true

  validates_by_schema

  after_destroy :update_major_order_value
  after_save :update_major_order_value

  scope :list, -> { order(Arel.sql('probability * impact DESC')) }

  class << self
    def risk(value)
      return if value.blank?

      if value < MEDIUM_THRESHOLD
        :low
      elsif value < HIGH_THRESHOLD
        :medium
      else
        :high
      end
    end
  end

  def to_s
    name
  end

  def risk_value
    probability_value * impact_value
  end

  def risk
    OrderUncertainty.risk(risk_value)
  end

  def probability_value
    OrderUncertainty.probabilities[probability]
  end

  def impact_value
    OrderUncertainty.impacts[impact]
  end

  protected

  def update_major_order_value
    raise # implement in child class
  end
end
