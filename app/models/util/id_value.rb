class IdValue < Struct.new(:id, :label)
  def to_s
    label
  end
end
