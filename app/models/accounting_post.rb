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
  include Closable

  belongs_to :portfolio_item

  has_ancestor_through_work_item :order
  has_ancestor_through_work_item :client


  before_validation :derive_offered_fields

  def validate_worktime(worktime)
    if worktime.report_type != AutoStartType::INSTANCE && description_required? && worktime.description.blank?
      worktime.errors.add(:description, 'Es muss eine Bemerkung angegeben werden')
    end

    if worktime.report_type != AutoStartType::INSTANCE && ticket_required? && worktime.ticket.blank?
      worktime.errors.add(:ticket, 'Es muss ein Ticket angegeben werden')
    end
  end

  private

  def derive_offered_fields
    if offered_hours.present? && offered_rate.present?
      self.offered_total = offered_hours * offered_rate
    elsif offered_total.present?
      self.offered_rate = nil
    end
  end

end
