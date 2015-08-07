# encoding: utf-8
# == Schema Information
#
# Table name: clients
#
#  id                      :integer          not null, primary key
#  work_item_id            :integer          not null
#  crm_key                 :string(255)
#  allow_local             :boolean          default(FALSE), not null
#  last_invoice_number     :integer          default(0)
#  invoicing_key           :string
#  last_billing_address_id :integer
#

# (c) Puzzle itc, Berne
# Diplomarbeit 2149, Xavier Hayoz

class Client < ActiveRecord::Base

  include BelongingToWorkItem
  include Evaluatable

  has_many :contacts, dependent: :destroy
  has_many :billing_addresses, dependent: :destroy

  belongs_to :last_billing_address, class_name: BillingAddress.name

  has_descendants_through_work_item :orders
  has_descendants_through_work_item :accounting_posts

  validates :work_item_id, uniqueness: true
  validates :crm_key, uniqueness: true, allow_blank: true
  validates :invoicing_key, uniqueness: true, allow_blank: true


  def default_billing_address
    last_billing_address || billing_addresses.first
  end

  ##### interface methods for Evaluatable #####

  def self.worktimes
    Worktime.all
  end

end
