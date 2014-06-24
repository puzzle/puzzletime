# == Schema Information
#
# Table name: order_comments
#
#  id         :integer          not null, primary key
#  order_id   :integer          not null
#  text       :text             not null
#  created_at :datetime
#  updated_at :datetime
#

class OrderComment < ActiveRecord::Base

  belongs_to :order

  scope :list, -> { order(:updated_at) }

end
