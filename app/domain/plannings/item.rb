# encoding: utf-8

module Plannings
  class Item
    attr_accessor :planning, :absencetime, :holiday

    def initialize
    end

    def day_attrs
      {}.tap do |params|
        params[:class] = class_name
        params[:title] = title
        params[:"data-id"] = @planning.id if @planning
      end
    end

    def to_s
      if @planning
        @planning.percent
      elsif @absencetime
        ''
      elsif !@absencetime && !@planning
        ''
      else
        '?'
      end
    end

    def title
      if @absencetime
        return "#{@absencetime.absence.name}: #{@absencetime.hours}"
      elsif @holiday
        if @holiday[1] > 0
          "Feiertag: #{@holiday[1]} Muss Stunden"
        else
          'Feiertag: Keine muss Stunden'
        end
      end
    end

    def class_name
      class_names = []

      if @planning
        class_names << '-definitive' if @planning.definitive?
        class_names << '-provisional' unless @planning.definitive?
        class_names << "-percent-#{@planning.percent.round(-1)}"
      end

      if @absencetime
        class_names << '-absence'
        class_names << '-absence-unpaid' unless @absencetime.absence.payed
      end

      if @holiday
        class_names << '-holiday'
      end

      class_names * ' '
    end
  end
end
