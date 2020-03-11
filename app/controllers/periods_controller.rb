class PeriodsController < ApplicationController
  skip_authorization_check

  before_action :set_period

  def show
    @period = Period.new if @period.nil?
  end

  def update
    @period = period_from_params
    fail ArgumentError, 'Start Datum nach End Datum' if @period.negative?

    session[:period] = [@period.start_date.to_s, @period.end_date.to_s, @period.label]
    # redirect_to_overview
    redirect_to sanitized_back_url
  rescue ArgumentError => ex # ArgumentError from Period.new or if period.negative?
    flash[:alert] = "Ungültige Zeitspanne: #{ex}"
    render action: 'show'
  end

  # set current period
  def destroy
    session[:period] = nil
    redirect_to sanitized_back_url
  end

  private

  def period_from_params
    if params[:period_shortcut]
      Period.parse(params[:period_shortcut])
    else
      Period.new(params[:period][:start_date],
                 params[:period][:end_date],
                 params[:period][:label])
    end
  end
end
