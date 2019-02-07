# Be sure to restart your server when you modify this file.

def dalli_reachable?
  Rails.cache.dalli.stats.values.any?
end

def memcache_configured?
  if Rails.env.production?
    ENV['RAILS_MEMCACHED_HOST'].present?
  elsif Rails.env.development?
    true
  else
    false
  end
end

Rails.application.config.session_store ActionDispatch::Session::CacheStore, expire_after: 12.hours

if memcache_configured? && !dalli_reachable?
  fail "As CSRF tokens are read from cache, we require a memcache instance to start"
end
