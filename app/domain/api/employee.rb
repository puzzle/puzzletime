module Api
  class Employee < BaseModel
    attribute :shortname, :string
    attribute :firstname, :string
    attribute :lastname, :string
    attribute :email, :string
    attribute :marital_status, :string
    attribute :nationalities, :array
    attribute :graduation, :string
    attribute :department, :string do
      department.shortname
    end

    def current_employment
      decorated_instance.current_employment
    end
  end
end
