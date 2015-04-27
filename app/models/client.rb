# encoding: utf-8
# == Schema Information
#
# Table name: clients
#
#  id           :integer          not null, primary key
#  work_item_id :integer          not null
#  crm_key      :string(255)
#  allow_local  :boolean          default(FALSE), not null
#

# (c) Puzzle itc, Berne
# Diplomarbeit 2149, Xavier Hayoz

class Client < ActiveRecord::Base

  include BelongingToWorkItem
  include Evaluatable

  has_many :contacts, dependent: :destroy
  has_many :billing_addresses, dependent: :destroy

  has_descendants_through_work_item :orders
  has_descendants_through_work_item :accounting_posts


  validates :crm_key, uniqueness: true, allow_blank: true

  ##### interface methods for Evaluatable #####

  def self.worktimes
    Worktime.all
  end

end
