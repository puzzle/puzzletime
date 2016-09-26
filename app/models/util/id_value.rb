class IdValue

  attr_reader :id, :label

  def initialize(id, label)
    @id = id
    @label = label
  end

  def to_s
    label
  end

end
