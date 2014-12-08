class OrderTeamMember < ActiveRecord::Base
  belongs_to :employee
  belongs_to :order

  def to_s
    comment? ? "#{employee.to_s} - #{comment}" : employee.to_s
  end

end