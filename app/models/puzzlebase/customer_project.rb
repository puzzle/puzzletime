class Puzzlebase::CustomerProject < Puzzlebase::Base  
  set_table_name 'TBL_CUSTOMER_PROJECT'  
  belongs_to :customer,
             :foreign_key => 'FK_CUSTOMER'
  belongs_to :project,
             :foreign_key => 'FK_PROJECT'
               
    MAPS_TO = ::Project         
    MAPPINGS = {:shortname => :S_PROJECT,
                :name      => :S_DESCRIPTION } 
    
  # Synchronizes the Projects and the Customers.
  def self.synchronize
    resetErrors
    Puzzlebase::Customer.updateAll
    updateAll    
    errors
  end     
    
  protected  

  def self.localFindOptions(original)
      { :include => :client,
        :conditions => ["projects.shortname = ? AND clients.shortname = ?", 
                      original.project.S_PROJECT, original.customer.S_CUSTOMER] }
  end
  
  def self.setReference(local, original)
    client = ::Client.find_by_shortname(original.customer.S_CUSTOMER)
    local.client_id = client.id if client
  end
  
  def self.updateAttributes(local, original)
    super local, original.project
  end
end
