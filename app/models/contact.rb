# encoding: utf-8
# == Schema Information
#
# Table name: contacts
#
#  id         :integer          not null, primary key
#  client_id  :integer          not null
#  lastname   :string(255)
#  firstname  :string(255)
#  function   :string(255)
#  email      :string(255)
#  phone      :string(255)
#  mobile     :string(255)
#  created_at :datetime
#  updated_at :datetime
#

class Contact < ActiveRecord::Base

  belongs_to :client

  has_many :orders
  has_many :billing_addresses

  validates :firstname, :lastname, presence: true

  scope :list, -> { order(:lastname, :firstname) }

  def to_s
    "#{lastname} #{firstname}"
  end

end
