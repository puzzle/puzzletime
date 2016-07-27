class Reports::Workload::OrdertimeEntry < Struct.new(:work_item, :hours, :billability)
  def label
    work_item.path_shortnames
  end

  def description
    work_item.name
  end

  def billability_percent
    100 * billability
  end
end
