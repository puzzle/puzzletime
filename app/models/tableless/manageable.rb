#only class methods, use extend Manageable in client
module Manageable

  def list(options = {})
    options[:order] ||= orderBy
    find(:all, options)  
  end  
    
  def label
    labels[1]
  end  
  
  def labelPlural
    labels[2]
  end
  
  def article
    labels[0]
  end
  
  def columnType(col)
    columns_hash[col.to_s].type
  end
  
  # may overwrite in mixin class
  def listFields
    fieldNames
  end
  
  # must overwrite in mixin class 
  def fieldNames
    []
  end
  
  # must overwrite in mixin class
  def labels
    ['Der', 'Eintrag', 'Einträge']
  end
  
  # may overwrite in mixin class
  def orderBy
    'name'
  end
    
end