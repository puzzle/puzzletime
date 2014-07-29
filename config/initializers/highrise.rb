if Settings.highrise.api_token
  Highrise::Base.site = Settings.highrise.url
  Highrise::Base.user = Settings.highrise.api_token
  Highrise::Base.format = :xml
end

ActiveResource::Base.logger = ActiveRecord::Base.logger