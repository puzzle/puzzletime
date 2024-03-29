# frozen_string_literal: true

Rswag::Ui.configure do |c|
  # List the Swagger endpoints that you want to be documented through the swagger-ui
  # The first parameter is the path (absolute or relative to the UI host) to the corresponding
  # JSON endpoint and the second is a title that will be displayed in the document selector
  # NOTE: If you're using rspec-api to expose Swagger files (under swagger_root) as JSON endpoints,
  # then the list below should correspond to the relative paths for those endpoints

  api_versions = Rails.root.join('app/controllers/api')
                      .children.filter_map { |p| p.to_s[%r{/(v\d+)\z}, 1] }

  api_versions.each do |version|
    if c.respond_to?(:openapi_endpoint)
      c.openapi_endpoint version, "API #{version} Docs"
    else
      # Remove after RSwag has reached v3.0
      c.swagger_endpoint version, "API #{version} Docs"
    end
  end
end
