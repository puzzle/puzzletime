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

  # Renders the full-size display of an attachment: an iframe for pdfs, an
  # image tag (optionally linked to the unresized original) otherwise. Each
  # variant applies its own class for styling; pass an additional :class
  # option to merge in extra classes.
  def attachment_display_tag(obj, **options)
    return pdf_iframe_tag(obj, options.except(:show_link)) if pdf?(obj)

    show_link = options.delete(:show_link)
    transformations = {
      resize_to_limit: [800, 1200]
    }
    image = attachment_image(obj, transformations)
    options[:class] = class_names(options[:class], 'img-responsive')
    tag = image_tag(image, options)

    return attachment_show_link(obj, tag) if show_link

    tag
  end

  private

  def pdf?(obj)
    obj.content_type == 'application/pdf'
  end

  def pdf_iframe_tag(obj, options)
    options[:class] = class_names(options[:class], 'attachment-frame')
    tag.iframe(src: "#{rails_blob_path(obj)}#navpanes=0", **options)
  end

  def attachment_image(obj, transformations = {})
    return obj.preview(transformations) unless obj.image?
    return obj.variant(transformations) if     obj.variable?

    obj
  end
end
