# encoding: utf-8
module WithPeriod
  extend ActiveSupport::Concern

  included do
    class_attribute :allow_unlimited_period
    self.allow_unlimited_period = true
  end

  private

  def set_period
    @period = build_period || default_period
  end

  def build_period
    if build_shortcut_period?
      Period.parse(params[:period_shortcut])
    elsif build_start_end_period?
      Period.new(params[:start_date].presence, params[:end_date].presence).tap do |period|
        fail ArgumentError, 'Start Datum nach End Datum' if period.negative?
      end
    end
  rescue ArgumentError => ex
    # from Period.new or if period.negative?
    flash.now[:alert] = "Ungültige Zeitspanne: #{ex}"
    params.delete(:start_date)
    params.delete(:end_date)
    params.delete(:period_shortcut)
    Period.new(nil, nil)
  end

  def default_period
    Period.new(nil, nil)
  end

  def build_shortcut_period?
    params[:period_shortcut].present?
  end

  def build_start_end_period?
    allow_unlimited_period && (params[:start_date].present? || params[:end_date].present?) ||
      !allow_unlimited_period && params[:start_date].present? && params[:end_date].present?
  end
end
