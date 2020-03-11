#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

module Plannings
  class Item
    attr_accessor :planning,
                  :absencetimes,
                  :holiday,
                  :general_must_hours,
                  :employment

    def initialize
      @absencetimes = []
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
      if absencetimes.present?
        absencetimes.map { |a| "Abwesenheit: #{a.hours} h" }.join("\n")
      elsif holiday
        if holiday[1] > 0
          "Feiertag: #{holiday[1]} Muss Stunden"
        else
          'Feiertag: Keine muss Stunden'
        end
      elsif employment.nil?
        'Nicht angestellt'
      elsif employment.percent.zero?
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

      if absencetimes.present?
        class_names << '-absence'
      end

      if employment.nil? || employment.percent.zero?
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
  end
end
