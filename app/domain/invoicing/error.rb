module Invoicing
  class Error < StandardError
    attr_reader :code, :data

    def initialize(message, code = nil, data = nil)
      super(message)
      @code = code
      @data = data
    end
  end
end
