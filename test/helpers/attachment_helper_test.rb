# frozen_string_literal: true

#  Copyright (c) 2006-2025, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

require 'test_helper'

# Test AttachmentHelper
class AttachmentHelperTest < ActionView::TestCase
  include AttachmentHelper

  setup do
    @expense = expenses(:pending)
  end

  test 'attachment_displayable? is false without a receipt' do
    assert_not attachment_displayable?(@expense.receipt)
  end

  test 'attachment_displayable? is true for an image receipt' do
    attach_image

    assert attachment_displayable?(@expense.receipt)
  end

  test 'attachment_displayable? is true for a pdf receipt' do
    attach_pdf

    assert attachment_displayable?(@expense.receipt)
  end

  test 'attachment_display_tag renders an img tag with the responsive class for an image receipt' do
    attach_image

    html = attachment_display_tag(@expense.receipt)

    assert_match(/<img class="img-responsive"/, html)
  end

  test 'attachment_display_tag renders an iframe with the frame class for a pdf receipt' do
    attach_pdf

    html = attachment_display_tag(@expense.receipt, show_link: true)

    assert_match(/<iframe /, html)
    assert_match(/class="attachment-frame"/, html)
    assert_match(/#navpanes=0"/, html)
    assert_no_match(/<a /, html)
  end

  private

  def attach_image
    @expense.receipt.attach(
      io: Rails.root.join('test/fixtures/files/lorem-ipsum.png').open,
      filename: 'receipt.png',
      content_type: 'image/png'
    )
  end

  def attach_pdf
    @expense.receipt.attach(
      io: StringIO.new('%PDF-1.4'),
      filename: 'receipt.pdf',
      content_type: 'application/pdf',
      identify: false
    )
  end
end
