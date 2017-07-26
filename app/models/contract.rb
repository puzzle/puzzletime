# encoding: utf-8

#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.


# == Schema Information
#
# Table name: contracts
#
#  id             :integer          not null, primary key
#  number         :string           not null
#  start_date     :date             not null
#  end_date       :date             not null
#  payment_period :integer          not null
#  reference      :text
#  sla            :text
#  notes          :text
#

class Contract < ActiveRecord::Base
  has_one :order

  validates_by_schema
  validates_date :start_date, :end_date
  validates :payment_period, inclusion: Settings.defaults.payment_periods


  after_initialize :set_default_payment_period

  def to_s
    number || ''
  end

  private

  def set_default_payment_period
    self.payment_period ||= Settings.defaults.payment_period
  end
end
