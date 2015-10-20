# encoding: utf-8
# == Schema Information
#
# Table name: order_comments
#
#  id         :integer          not null, primary key
#  order_id   :integer          not null
#  text       :text             not null
#  creator_id :integer
#  updater_id :integer
#  created_at :datetime
#  updated_at :datetime
#

class OrderComment < ActiveRecord::Base
  ### ASSOCIATIONS

  belongs_to :order
  belongs_to :creator, class_name: 'Employee'
  belongs_to :updater, class_name: 'Employee'

  ### VALIDATIONS

  validates_by_schema
  validates :creator, :updater, presence: true

  ### SCOPES

  scope :list, -> { includes(:creator).order('updated_at DESC') }


  ### INSTANCE METHODS

  def to_s
    "#{creator}: #{text.truncate(20)}"
  end
end
