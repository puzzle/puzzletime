#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

module Completable
  extend ActiveSupport::Concern

  include ActionView::Helpers::JavaScriptHelper
  include ActionView::Helpers::TagHelper
  include UtilityHelper
  include CompletableHelper

  included do
    class_attribute :completable_attr

    skip_authorize_resource
    before_action :authorize

    before_save :validate_date
    before_render_form :set_dates, :set_selected_month

    helper_method :completable_attr
  end

  private

  def validate_date
    unless completion_dates.include?(entry_date)
      entry.errors.add(completable_attr, 'ist nicht erlaubt')
      throw(:abort)
    end
  end

  def set_selected_month
    # Selecting a month in the future is fine, as an invalid selection
    # or even no selection ends up selecting the first (and most recent)
    # month.
    if entry_date.present?
      @selected_month = entry_date + 1.month
      @selected_month = @selected_month.end_of_month
    end
  end

  def set_dates
    @dates = month_labels(completion_dates)
  end

  def month_labels(dates)
    dates.collect do |date|
      [date, date ? format_month(date) : 'Nie']
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
    date = entry_date
    string = format_month(date)
    { id: entry.id,
      value: date,
      label: string,
      content: date && "#{j(completed_icon(date))} #{string}" }
  end

  def entry_date
    entry.send(completable_attr)
  end
end
