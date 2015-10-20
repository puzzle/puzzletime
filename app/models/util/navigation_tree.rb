# encoding: utf-8

class NavigationTree
  def initialize
    @tree = []
  end

  def arrive(model_class, page, group_id, up)
    if @tree.empty? || (group_id && current[:group_id] != group_id)
      push(model_class, group_id, page)
    elsif up && depth > 1
      @tree.pop
    else
      set(model_class, page)
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

  def set(model_class, page)
    if current[:model] == model_class
      current[:page] = page
    else
      @tree = []
      push(model_class, nil, page)
    end
  end

  def push(model_class, group_id, page)
    @tree.push(create(model_class, group_id, page))
  end

  def create(model_class, group_id, page)
    { model: model_class, group_id: group_id, page: page }
  end
end
