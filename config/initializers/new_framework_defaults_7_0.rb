# frozen_string_literal: true

# New default is `OpenSSL::Digest::SHA256`, we still use the old value for now
Rails.application.config.active_support.key_generator_hash_digest_class = OpenSSL::Digest::SHA1

# Enable parameter wrapping for JSON.
# Previously this was set in an initializer. It's fine to keep using that initializer if you've customized it.
# To disable parameter wrapping entirely, set this config to `false`.
# Rails.application.config.action_controller.wrap_parameters_by_default = true
