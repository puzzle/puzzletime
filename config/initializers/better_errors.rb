if defined? BetterErrors && ENV['BETTER_ERRORS_URL'].present?
  BetterErrors.editor = proc { |full_path, line|
    namespace = OpenStruct.new(full_path: "/hello/world", line: 123)
    Haml::Engine.new(ENV['BETTER_ERRORS_URL']).render(namespace.instance_eval { binding})
  }
end