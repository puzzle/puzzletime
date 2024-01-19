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

  # This method smells of :reek:TooManyStatements
  def run
    employee        = Employee.create_with(@data[:employee]).find_or_create_by!(shortname: @data[:shortname])
    role            = EmploymentRole.find_or_create_by!(@data[:role])
    level           = EmploymentRoleLevel.find_or_create_by!(@data[:level])
    employment      = Employment.find_or_initialize_by(@data[:employment])
    role_employment = EmploymentRolesEmployment.find_or_initialize_by(@data[:role_employment])

    role_employment.employment            = employment
    role_employment.employment_role       = role
    role_employment.employment_role_level = level

    employment.employee                     = employee
    employment.employment_roles_employments = [role_employment]

    employment.save!
  end
end
