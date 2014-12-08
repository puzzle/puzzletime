class OrderContact < ActiveRecord::Base
  belongs_to :contact
  belongs_to :order
end