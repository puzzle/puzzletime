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

  validates :start_date, :end_date, :payment_period, presence: true
  validates_date :start_date, :end_date

  def to_s
    number || ""
  end

end
