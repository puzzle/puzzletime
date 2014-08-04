# encoding: utf-8
# == Schema Information
#
# Table name: departments
#
#  id        :integer          not null, primary key
#  name      :string(255)      not null
#  shortname :string(3)        not null
#


class Department < ActiveRecord::Base

  include Evaluatable

  has_many :orders
  
  protect_if :worktimes, 'Dieser Eintrag kann nicht gelöscht werden, da ihm noch Arbeitszeiten zugeordnet sind'
  protect_if :orders, 'Dieser Eintrag kann nicht gelöscht werden, da ihm noch Aufträge zugeordnet sind'

  scope :list, -> { order('name') }

  def to_s
    name
  end

  def worktimes
    orders.collect{|o| o.worktimes }
  end

  ##### interface methods for Evaluatable #####

  def self.worktimes
    Worktime.all
  end

end
