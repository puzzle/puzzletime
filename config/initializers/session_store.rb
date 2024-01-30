# Be sure to restart your server when you modify this file.

# The session_store setup is handled in the environment configs


def cache_readable?
  Rails.cache.stats.values.any?
end

def skip_memcache?
  ENV['SKIP_MEMCACHE_CHECK'].present?
end

def memcache_used?
  Rails.application.config.session_store == ActionDispatch::Session::CacheStore
end

def warn_about_missing_memcache
  return if skip_memcache?
  return if !memcache_used?
  return if cache_readable?

  raise 'As CSRF tokens are read from cache, we require a memcache instance to start'
end

# We expect memcache to work in production.
# Prevents an error with the rails console on OpenShift
warn_about_missing_memcache
