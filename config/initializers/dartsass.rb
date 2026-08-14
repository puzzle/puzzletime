# frozen_string_literal: true

# Be sure to restart your server when you modify this file.

# Two entrypoints: application (all views) and phone (layouts/phone.html.haml).
# Paths are relative to app/assets/stylesheets/ (source) and
# app/assets/builds/ (output).
Rails.application.config.dartsass.builds = {
  'application.scss' => 'application.css',
  'phone.scss' => 'phone.css'
}

# Readable, unminified CSS with source maps outside production; compressed
# and map-free (the gem's own default) in production.
unless Rails.env.production?
  Rails.application.config.dartsass.build_options = ['--style=expanded']
end
