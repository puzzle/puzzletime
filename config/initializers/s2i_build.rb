if ENV['S2I_BUILD']
  module ValidatesBySchema::ClassMethods
    def validates_by_schema(options = {})
      # do nothing on s2i build to prevent db initialisation as db does not exist during s2i build
    end
  end
end