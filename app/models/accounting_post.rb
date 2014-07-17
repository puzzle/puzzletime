# == Schema Information
#
# Table name: accounting_posts
#
#  id                   :integer          not null, primary key
#  work_item_id         :integer          not null
#  portfolio_item_id    :integer
#  reference            :string(255)
#  offered_hours        :integer
#  offered_rate         :integer
#  discount_percent     :integer
#  discount_fixed       :integer
#  report_type          :string(255)
#  billable             :boolean          default(TRUE), not null
#  description_required :boolean          default(FALSE), not null
#  ticket_required      :boolean          default(FALSE), not null
#  closed               :boolean          default(FALSE), not null
#

class AccountingPost < ActiveRecord::Base

  include BelongingToWorkItem

  belongs_to :portfolio_itme

  has_one_through_work_item :order
  has_one_through_work_item :client
  has_many_through_work_item :worktimes

  # TODO propagate closed to work items when changed
end
