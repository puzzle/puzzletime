module Conditioner
  
  def append_conditions(existing, appends, cat = 'AND')
    if existing.nil?
      existing = ['']
    elsif existing.empty?   #keep object reference
      existing.push ''  
    else
      existing[0] = "( #{existing[0]} ) #{cat} "
    end
    existing[0] += appends[0]
    existing.concat appends[1..-1]
  end
  
  def clone_conditions(conditions) 
    return conditions.clone if conditions
    []
  end
  
  def clone_options(options = {})
    options = options.clone
    options[:conditions] = clone_conditions options[:conditions]
    options
  end
  
end