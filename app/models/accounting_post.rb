# == Schema Information
#
# Table name: accounting_posts
#
#  id                   :integer          not null, primary key
#  path_item_id         :integer          not null
#  portfolio_item_id    :integer
#  description          :text
#  reference            :string(255)
#  offered_hours        :integer
#  offered_rate         :integer
#  discount_percent     :integer
#  discount_fixed       :integer
#  report_type          :string(255)
#  billable             :boolean          default(TRUE), not null
#  description_required :boolean          default(FALSE), not null
#  ticket_required      :boolean          default(FALSE), not null
#  open                 :boolean          default(TRUE), not null
#  order_closed         :boolean          default(FALSE), not null
#

class AccountingPost < ActiveRecord::Base

  belongs_to :path_item
  belongs_to :portfolio_itme

end
