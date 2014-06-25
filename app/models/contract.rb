# encoding: utf-8

# == Schema Information
#
# Table name: contracts
#
#  id             :integer          not null, primary key
#  number         :string(255)      not null
#  start_date     :date
#  end_date       :date
#  payment_period :integer
#  reference      :string(255)
#

class Contract < ActiveRecord::Base

  has_one :order

  validates :start_at, :finish_at, :payment_period, presence: true
  validates_date :start_at, :finish_at

  def to_s
    number
  end

end
