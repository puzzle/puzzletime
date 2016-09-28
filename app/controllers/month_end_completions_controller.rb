class MonthEndCompletionsController < CrudController

  include ActionView::Helpers::JavaScriptHelper

  self.permitted_attrs = [:completed_month_end_at]

  skip_authorize_resource
  before_action :authorize_employee

  before_save :validate_completion_date
  before_render_form :set_completion_dates

  class << self
    def model_class
      Order
    end
  end

  private

  def entry
    @order ||= model_scope.find(params[:order_id])
  end

  def validate_completion_date
    unless completion_dates.include?(entry.completed_month_end_at)
      entry.errors.add(:completed_month_end_at, 'ist nicht erlaubt')
      false
    end
  end

  def set_completion_dates
    @completion_dates = month_labels(completion_dates)
  end

  def month_labels(dates)
    dates.collect do |date|
      if date
        [date, I18n.l(date, format: :month)]
      else
        [date, 'Nie']
      end
    end
  end

  def completion_dates
    today = Time.zone.today
    if current_user.management?
      Array.new(12) { |i| (today - i.months).end_of_month } + [nil]
    else
      [today - 1.month, today].collect(&:end_of_month)
    end
  end

  def js_entry
    date = entry.completed_month_end_at
    string = date && I18n.l(date, format: :month)
    { id: entry.id,
      value: date,
      label: string,
      content: date && "#{j(state_icon)} #{string}" }
  end

  def state_icon
    if entry.recently_completed_month_end?
      '<span class="icon-disk green"></span>'
    else
      '<span class="icon-square red"></span>'
    end
  end

  def authorize_employee
    authorize!(:update_month_end_completions, entry)
  end

end
