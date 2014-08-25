# encoding: UTF-8

class Puzzlebase::CustomerProject < Puzzlebase::Base

  belongs_to :customer,
             foreign_key: 'FK_CUSTOMER'
  belongs_to :project,
             foreign_key: 'FK_PROJECT'

  MAPS_TO = ::Project
  MAPPINGS = { shortname: :S_PROJECT,
               name: :S_DESCRIPTION }
  FIND_OPTIONS = { include: 'project',
                   joins: 'project',
                   conditions: ['B_SYNCTOPUZZLETIME AND TBL_PROJECT.FK_PROJECT IS NULL'] }

  def self.table_name
    'TBL_CUSTOMER_PROJECT'
  end

  def self.primary_key
    'PK_CUSTOMER_PROJECT'
  end

  # Synchronizes the Projects and the Customers.
  def self.synchronize
    reset_errors
    Puzzlebase::Unit.update_all
    Puzzlebase::Customer.update_all
    update_all
    remove_unused
    errors
  end

  def self.remove_unused
    Puzzlebase::Customer.remove_unused
    Puzzlebase::Project.remove_unused
  end

  protected

  def self.update_local(original)
    success = super
    Puzzlebase::Project.update_children original.project, find_local(original) if success
  end

  def self.local_find_options(original)
    { include: :client,
      references: :client,
      conditions: ['projects.shortname = ? AND clients.shortname = ? AND projects.parent_id IS NULL',
                   original.project.S_PROJECT, original.customer.S_CUSTOMER] }
  end

  def self.set_reference(local, original)
    client = ::Client.find_by_shortname(original.customer.S_CUSTOMER)
    department = ::Department.find_by_shortname(original.project.unit.S_UNIT)
    local.client_id = client.id if client
    local.department_id = department.id if department
  end

  def self.update_attributes(local, original)
    super local, original.project
  end
end
