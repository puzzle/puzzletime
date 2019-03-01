module Api
  class EmploymentRolesEmployment < BaseModel
    attribute :name, :string do
      decorated_instance.employment_role&.name
    end
    attribute :percent, :integer
  end
end