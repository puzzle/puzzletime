# patches schema validations for rails 4.1. should not be required for version after 1.0.0

module ActiveRecord
  class Base
    protected

    def run_validations_with_schema_validations!
      load_schema_validations unless schema_validations_loaded?
      run_validations_without_schema_validations!
    end
    alias_method_chain :run_validations!, :schema_validations
  end
end