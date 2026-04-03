# frozen_string_literal: true

# Creates new Testusers with all needed associations
class CreateTestuser
  def self.run(data)
    new(data).run
  end

  def initialize(data)
    @data = {}
    @data[:shortname]       = data[:shortname]
    @data[:employee]        = data[:employee]
    @data[:role]            = data[:role]
    @data[:level]           = data[:level]
    @data[:employment]      = data[:employment]
    @data[:role_employment] = data[:role_employment]
  end

  def run
    employment.save!
  end

  def employment
    @employment ||=
      begin
        emp = Employment.find_or_initialize_by(@data[:employment])
        emp.employee = employee
        emp.employment_roles_employments = [role_employment]
      end
  end

  def employee
    @employee ||= Employee.create_with(@data[:employee]).find_or_create_by!(shortname: @data[:shortname])
  end

  def role_employment
    @role_employment ||=
      begin
        ere = EmploymentRolesEmployment.find_or_initialize_by(@data[:role_employment])
        ere.employment = employment
        ere.employment_role = role
        ere.employment_role_level = level
      end
  end

  def role
    @role ||= EmploymentRole.find_or_create_by!(@data[:role])
  end

  def level
    @level ||= EmploymentRoleLevel.find_or_create_by!(@data[:level])
  end
end
