# frozen_string_literal: true

module EmailHelper
  def email_image_tag(image, **)
    attachments.inline[image] = Rails.root.join("app/assets/images/#{image}").read
    image_tag(attachments[image].url, **)
  end
end
