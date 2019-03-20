# frozen_string_literal: true

module AttachmentHelper
  def attachment_download_link(obj, **options)
    link_to(obj.filename, rails_blob_path(obj, disposition: 'attachment'), options)
  end

  def attachment_show_link(obj, label, **options)
    link_to(label, rails_blob_path(obj), options)
  end

  def attachment_displayable?(receipt)
    receipt.attached? && (receipt.image? || receipt.previewable?)
  end

  def attachment_image_tag(obj, **options)
    transformations =
      {
        auto_orient: true,
        resize: '800x1200>'
      }
    image = attachment_image(obj, transformations)
    tag   = image_tag(image, options)

    return attachment_show_link(obj, tag, options) if options[:show_link]

    tag
  end

  private

  def attachment_image(obj, transformations = {})
    return obj.preview(transformations) unless obj.image?
    return obj.variant(transformations) if     obj.variable?

    obj
  end

end
