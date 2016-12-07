# encoding: utf-8

module Plannings
  class Item
    attr_accessor :planning, :absencetime

    def initialize
    end

    def day_params
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
      else
        '?'
      end
    end

    def title
      if @absencetime
        "#{@absencetime.absence.name}: #{@absencetime.hours}"
      end
    end

    def class_name
      class_names = []

      if @planning
        class_names << '-definitive' if @planning.definitive?
        class_names << '-provisional' unless @planning.definitive?
        class_names << "-percent-#{@planning.percent.round(-1)}"
      end

      class_names << '-absence' if @absencetime

      class_names * ' '
    end
  end
end
