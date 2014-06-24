# == Schema Information
#
# Table name: contacts
#
#  id         :integer          not null, primary key
#  lastname   :string(255)
#  firstname  :string(255)
#  function   :string(255)
#  email      :string(255)
#  telephone  :string(255)
#  mobile     :string(255)
#  created_at :datetime
#  updated_at :datetime
#

class Contact < ActiveRecord::Base

  has_many :orders
  has_many :billing_addresses

  validates :firstname, :lastname, presence: true

  scope :list, -> { order(:lastname, :firstname) }

  def to_s
    "#{lastname} #{firstname}"
  end

end
