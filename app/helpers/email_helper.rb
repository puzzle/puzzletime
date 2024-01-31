module EmailHelper
  def email_image_tag(image, **)
    attachments.inline[image] = File.read(Rails.root.join("app/assets/images/#{image}"))
    image_tag(attachments[image].url, **)
  end
end
