class NavigationTree
  def initialize
    @tree = Array.new  
  end
  
  def arrive(modelClass, page, group_id, up)
    if @tree.empty? || (group_id && current[:group_id] != group_id)
      push(modelClass, group_id, page)
    elsif up && depth > 1
      @tree.pop
    else
      set(modelClass, page)   
    end
  end
  
  def previous
    @tree[-2] if depth > 1
  end
  
  def current
    @tree.last
  end
  
  def depth
    @tree.size
  end
  
  def group_id
    current[:group_id]
  end
  
  def page
    current[:page]
  end
  
  def prev_model
    previous[:model] if previous
  end
  
  def prev_parent?
    depth > 2 && previous[:model] == current[:model] && @tree[-3][:model] == current[:model]
  end
  
private  

  def set(modelClass, page)
    if current[:model] == modelClass
      current[:page] = page
    else
      @tree = Array.new
      push(modelClass, nil, page)
    end
  end
  
  def push(modelClass, group_id, page)
    @tree.push(create(modelClass, group_id, page))
  end
  
  def create(modelClass, group_id, page)
    {:model => modelClass, :group_id => group_id, :page => page}
  end
  
end