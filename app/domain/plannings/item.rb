# encoding: utf-8

module Plannings
  class Item
    attr_accessor :planning,
                  :absencetime,
                  :holiday,
                  :general_must_hours,
                  :employment

    def initialize
    end

    def day_attrs
      {}.tap do |params|
        params[:class] = class_name
        params[:title] = title
        params[:'data-id'] = planning.id if planning
      end
    end

    def to_s
      if planning
        planning.percent.to_s
      else
        ''
      end
    end

    def title
      if absencetime
        "#{absencetime.absence.name}: #{absencetime.hours}"
      elsif holiday
        if holiday[1] > 0
          "Feiertag: #{holiday[1]} Muss Stunden"
        else
          'Feiertag: Keine muss Stunden'
        end
      elsif has_zero_employment
        'Unbezahlte Abwesenheit'
      end
    end

    def class_name
      class_names = []

      if planning
        class_names << '-definitive' if planning.definitive?
        class_names << '-provisional' unless planning.definitive?
        class_names << "-percent-#{planning.percent.round(-1)}"
      end

      if absencetime
        class_names << '-absence'
      end

      if has_zero_employment
        class_names << '-absence-unpaid'
      end

      if holiday
        class_names << '-holiday'
      end

      class_names.join(' ')
    end

    def planned_hours
      if planning
        planning.percent / 100.0 * general_must_hours
      else
        0
      end
    end

    private

    def has_zero_employment
      employment && employment.percent == 0
    end

  end
end
