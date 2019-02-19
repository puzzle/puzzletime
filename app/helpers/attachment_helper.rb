# frozen_string_literal: true

module AttachmentHelper
  def attachment_download_link(obj, **options)
    link_to(obj.filename, rails_blob_path(obj, disposition: 'attachment'), options)
  end

  def attachment_show_link(obj, label, **options)
    link_to(label, rails_blob_path(obj), options)
  end

  def attachment_image_tag(obj, **options)
    path =
      if obj.image?
        rails_blob_url(obj)
      elsif obj.previewable?
        obj.preview({})
      end

    if options[:show_link]
      attachment_show_link(obj, image_tag(path, options), options)
    else
      image_tag(path, options)
    end
  end

end
