class WorktimesCommitsController < CrudController

  include ActionView::Helpers::JavaScriptHelper

  self.permitted_attrs = [:committed_worktimes_at]

  skip_authorize_resource
  before_action :authorize_employee

  before_save :validate_commit_date
  before_render_form :set_commit_dates

  class << self
    def model_class
      Employee
    end
  end

  private

  def entry
    @employee ||= model_scope.find(params[:employee_id])
  end

  def validate_commit_date
    unless commit_dates.include?(entry.committed_worktimes_at)
      entry.errors.add(:committed_worktimes_at, 'ist nicht erlaubt')
      false
    end
  end

  def set_commit_dates
    @commit_dates = month_labels(commit_dates)
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

  def commit_dates
    today = Time.zone.today
    if current_user.management?
      Array.new(12) { |i| (today - i.months).end_of_month } + [nil]
    else
      [today - 1.month, today].collect(&:end_of_month)
    end
  end

  def js_entry
    date = entry.committed_worktimes_at
    string = date && I18n.l(date, format: :month)
    { id: entry.id,
      value: date,
      label: string,
      content: date && "#{j(state_icon)} #{string}" }
  end

  def state_icon
    if entry.recently_committed_worktimes?
      '<span class="icon-disk green"></span>'
    else
      '<span class="icon-square red"></span>'
    end
  end

  def authorize_employee
    authorize!(:update_committed_worktimes, entry)
  end

end
