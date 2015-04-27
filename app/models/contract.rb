# encoding: utf-8
# == Schema Information
#
# Table name: contracts
#
#  id             :integer          not null, primary key
#  number         :string(255)      not null
#  start_date     :date             not null
#  end_date       :date             not null
#  payment_period :integer          not null
#  reference      :text
#  sla            :text
#  notes          :text
#

class Contract < ActiveRecord::Base

  has_one :order

  validates_date :start_date, :end_date

  def to_s
    number || ""
  end

end
