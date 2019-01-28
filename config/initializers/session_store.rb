# Be sure to restart your server when you modify this file.

#Rails.application.config.session_store :cookie_store, key: '_puzzletime_session'
Rails.application.config.session_store ActionDispatch::Session::CacheStore, expire_after: 12.hours
unless Rails.env.test? || Rails.cache.dalli.stats.values.any?(&:present?)
  fail "As CSRF tokens are read from cache, we require a memcache instance to start"
end
