# frozen_string_literal: true

#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

module Graphs
  class Timebox
    PIXEL_PER_HOUR = 8.0

    MUST_HOURS_COLOR = '#FF0000'
    BLANK_COLOR = 'transparent'

    attr_accessor :height, :worktime
    attr_reader :color, :tooltip

    include ActionView::Helpers::OutputSafetyHelper

    class << self
      def must_hours(must_hours)
        new(nil, MUST_HOURS_COLOR, 1, 'Sollzeit ('.html_safe << format_hour(must_hours) << ')')
      end

      def blank(hours)
        new(nil, BLANK_COLOR, height_from_hours(hours), '')
      end

      def height_from_hours(hours)
        # Round to fix pixel display issues
        rounded = (hours * 4).round / 4.0
        rounded * PIXEL_PER_HOUR
      end

      def format_hour(hour)
        ActionController::Base.helpers.number_with_precision(hour, precision: 2, delimiter: '\'')
      end
    end

    def initialize(worktime, color = nil, hgt = nil, tooltip = nil)
      if worktime
        @worktime = worktime
        hgt ||= self.class.height_from_hours worktime.hours
        tooltip ||= tooltip_for worktime
      end
      @height = (hgt * 10).round / 10.0
      @color = color
      @tooltip = tooltip
    end

    def stretch(factor)
      @height *= factor
    end

    private

    def tooltip_for(worktime)
      Graphs::Timebox.format_hour(worktime.hours) << ': ' << worktime.account.label_verbose
    end
  end
end
