# frozen_string_literal: true

module AttachmentHelper
  def attachment_download_link(obj, **options)
    link_to(obj.filename, rails_blob_path(obj, disposition: 'attachment'), options)
  end

  def attachment_show_link(obj, label, **options)
    link_to(label, rails_blob_path(obj), options)
  end

  def attachment_displayable?(receipt)
    receipt.attached? && (receipt.image? || pdf?(receipt) || receipt.previewable?)
  end

  def attachment_image_tag(obj, **options)
    return attachment_pdf_tag(obj, options.except(:show_link)) if pdf?(obj)

    transformations = {
      resize_to_limit: [800, 1200]
    }
    image = attachment_image(obj, transformations)
    tag   = image_tag(image, options)

    return attachment_show_link(obj, tag, **options) if options[:show_link]

    tag
  end

  private

  def pdf?(obj)
    obj.content_type == 'application/pdf'
  end

  def attachment_pdf_tag(obj, options)
    options[:class] = [options[:class], 'attachment-pdf'].compact.join(' ')
    tag.iframe(src: "#{rails_blob_path(obj)}#navpanes=0", **options)
  end

  def attachment_image(obj, transformations = {})
    return obj.preview(transformations) unless obj.image?
    return obj.variant(transformations) if     obj.variable?

    obj
  end
end
