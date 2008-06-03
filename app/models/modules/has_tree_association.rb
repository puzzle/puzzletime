module HasTreeAssociation
  
  include Conditioner
 
  def sum(column_name, options = {})
    options = restrict_conditions options
    @reflection.klass.sum(column_name, options)
  end
  
  def find(*args)
    case args.first
      when :first, :all then 
        options = restrict_conditions args.extract_options!
        @reflection.klass.find(args.first, options)
      else 
        @reflection.klass.find(args)
    end
  end
  
  def count(*args)
    column_name, options = @reflection.klass.send(:construct_count_options_from_args, *args)
    options = restrict_conditions options
    @reflection.klass.count(column_name, options)
  end
    
  def restrict_conditions(options)
    options = clone_options options
    append_conditions(options[:conditions], 
                      [ "worktimes.project_id = projects.id AND #{@owner.id} = ANY (projects.path_ids)" ])
    options[:include] = 'project'
    options
  end

end