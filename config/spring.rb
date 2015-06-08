class MetalRunner
  def env(*)
    "test"
  end

  def exec_name
    "m"
  end
end

Spring.register_command "m", MetalRunner.new