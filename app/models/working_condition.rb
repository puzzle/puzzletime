# encoding: utf-8
# == Schema Information
#
# Table name: working_conditions
#
#  id                     :integer          not null, primary key
#  valid_from             :date
#  vacation_days_per_year :decimal(5, 2)    not null
#  must_hours_per_day     :decimal(4, 2)    not null
#


class WorkingCondition < ActiveRecord::Base

  validates_by_schema
  validates :valid_from, uniqueness: true
  validates :must_hours_per_day,
            numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 24 }
  validates :vacation_days_per_year,
            numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 365 }
  validate :exactly_one_without_valid_from


  before_destroy :protect_blank_valid_from
  after_save :clear_cache
  after_destroy :clear_cache

  delegate :clear_cache, to: :class

  scope :list, -> { order('(CASE WHEN valid_from IS NULL THEN 0 ELSE 1 END) DESC, valid_from DESC') }

  class << self
    def todays_value(attr)
      if @today != Time.zone.today
        @today = Time.zone.today
        @todays_values = {}
      end
      @todays_values[attr.to_s] ||= value_at(@today, attr)
    end

    def value_at(date, attr)
      each_of(attr, date, date) { |v, _, _| return v }
    end

    def sum_with(attr, period)
      sum = 0
      each_period_of(attr, period) do |p, val|
        sum += yield(p, val)
      end
      sum
    end

    def each_period_of(attr, period)
      period ||= Period.new(nil, nil)
      each_of(attr, period.start_date, period.end_date) do |val, from, following|
        not_first_from = from && (period.start_date.nil? || from > period.start_date)
        not_last_following = following && (period.end_date.nil? || following <= period.end_date)
        start = not_first_from ? from : period.start_date
        finish = not_last_following ? following - 1 : period.end_date
        yield(Period.new(start, finish), val)
      end
    end

    def each_of(attr, start_date, end_date)
      conditions = cached + [{}]
      conditions.each_cons(2) do |a, b|
        from = a['valid_from']
        following = b['valid_from']
        if (from.nil? || end_date.nil? || from <= end_date) &&
           (following.nil? || start_date.nil? || following > start_date)
          yield(a[attr.to_s], from, following)
        end
      end
    end

    def cached
      # double cache for best performance
      RequestStore.store[model_name.route_key] ||=
        Rails.cache.fetch(model_name.route_key) do
          order('(CASE WHEN valid_from IS NULL THEN 0 ELSE 1 END), valid_from').collect(&:attributes)
        end
    end

    def clear_cache
      RequestStore.store[model_name.route_key] = nil
      Rails.cache.clear(model_name.route_key)
      @todays_values = {}
      true
    end
  end

  def to_s
    valid_from? ? I18n.l(valid_from) : ''
  end

  private

  def exactly_one_without_valid_from
    first_id = WorkingCondition.where(valid_from: nil).pluck(:id).first
    if id == first_id && valid_from?
      errors.add(:valid_from, 'darf für den ersten Eintrag nicht gesetzt werden.')
    end
  end

  def protect_blank_valid_from
    if valid_from.blank?
      errors.add(:base, 'Der erste Eintrag darf nicht gelöscht werden.')
      false
    end
  end
end
