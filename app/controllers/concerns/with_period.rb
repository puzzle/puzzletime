# encoding: utf-8
module WithPeriod
  private

  def set_period
    @period = build_period || default_period
  end

  def build_period
    return nil if params[:start_date].blank? && params[:end_date].blank?

    Period.retrieve(params[:start_date].presence, params[:end_date].presence).tap do |period|
      fail ArgumentError, 'Start Datum nach End Datum' if period.negative?
    end
  rescue ArgumentError => ex
    # from Period.retrieve or if period.negative?
    flash.now[:alert] = "Ungültige Zeitspanne: #{ex}"
    params.delete(:start_date)
    params.delete(:end_date)
    Period.new(nil, nil)
  end

  def default_period
    Period.new(nil, nil)
  end
end
