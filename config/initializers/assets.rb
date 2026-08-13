# frozen_string_literal: true

# Be sure to restart your server when you modify this file.

# Propshaft precompiles everything on the load path -- no version, precompile
# list, or manifest is needed. app/assets/fonts is already an implicit load
# path (Rails registers every app/assets/* subdirectory), so this line is now
# a no-op kept only for clarity; harmless since Propshaft dedupes paths.
Rails.application.config.assets.paths << Rails.root.join('app/assets/fonts')

# Keep the raw .scss sources out of the published asset set -- only the
# dartsass-rails build output (app/assets/builds/*.css) should be served.
Rails.application.config.assets.excluded_paths << Rails.root.join('app/assets/stylesheets')
