# frozen_string_literal: true

class ReportType
  module Accessors # :nodoc:
    def report_type
      type = self['report_type']
      type.is_a?(String) ? ReportType[type] : type
    end

    def report_type=(type)
      type = type.key if type.is_a? ReportType
      self['report_type'] = type
    end
  end
end
