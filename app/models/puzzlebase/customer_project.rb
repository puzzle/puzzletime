class Puzzlebase::CustomerProject < Puzzlebase::Base

  self.table_name = 'TBL_CUSTOMER_PROJECT'
  self.primary_key = 'PK_CUSTOMER_PROJECT'

  belongs_to :customer,
             foreign_key: 'FK_CUSTOMER'
  belongs_to :project,
             foreign_key: 'FK_PROJECT'

  MAPS_TO = ::Project
  MAPPINGS = { shortname: :S_PROJECT,
               name: :S_DESCRIPTION }
  FIND_OPTIONS = { include: 'project',
                   conditions: ['B_SYNCTOPUZZLETIME AND TBL_PROJECT.FK_PROJECT IS NULL'] }

  # Synchronizes the Projects and the Customers.
  def self.synchronize
    resetErrors
    Puzzlebase::Unit.updateAll
    Puzzlebase::Customer.updateAll
    updateAll
    removeUnused
    errors
  end

  def self.removeUnused
    Puzzlebase::Customer.removeUnused
    Puzzlebase::Project.removeUnused
  end

  protected

  def self.updateLocal(original)
    success = super
    Puzzlebase::Project.updateChildren original.project, findLocal(original) if success
  end

  def self.localFindOptions(original)
    { include: :client,
      conditions: ['projects.shortname = ? AND clients.shortname = ? AND projects.parent_id IS NULL',
                   original.project.S_PROJECT, original.customer.S_CUSTOMER] }
  end

  def self.setReference(local, original)
    client = ::Client.find_by_shortname(original.customer.S_CUSTOMER)
    department = ::Department.find_by_shortname(original.project.unit.S_UNIT)
    local.client_id = client.id if client
    local.department_id = department.id if department
  end

  def self.updateAttributes(local, original)
    super local, original.project
  end
end
