# == Schema Information
#
# Table name: order_targets
#
#  id              :integer          not null, primary key
#  target_scope_id :integer          not null
#  order_id        :integer          not null
#  rating          :string(255)
#  comment         :text
#  created_at      :datetime
#  updated_at      :datetime
#

class OrderTarget < ActiveRecord::Base

  RATINGS = %w(green orange red)

  belongs_to :order
  belongs_to :target_scope

  validates :rating, inclusion: RATINGS
  validates :comment, presence: { if: -> { rating != 'green' } }

  scope :list, -> { includes(:target_scope).references(:target_scope).order(target_scopes: :name) }

end
