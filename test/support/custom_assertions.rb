# frozen_string_literal: true

#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

# A handful of convenient assertions. The aim of custom assertions is to
# provide more specific error messages and to perform complex checks.
#
# Ideally, include this module into your test_helper.rb file:
#  # at the beginning of the file:
#  require 'support/custom_assertions'
#
#  # inside the class definition:
#  include CustomAssertions
module CustomAssertions
  # Asserts that regexp occurs exactly expected times in string.
  def assert_count(expected, regexp, string, msg = '')
    actual = string.scan(regexp).size
    msg = message(msg) do
      "Expected #{mu_pp(regexp)} to occur #{expected} time(s), " \
        "but occured #{actual} time(s) in \n#{mu_pp(string)}"
    end

    assert_equal expected, actual, msg
  end

  # Asserts that the given active model record is valid.
  # This method used to be part of Rails but was deprecated, no idea why.
  def assert_valid(record, msg = '')
    record.valid?
    msg = message(msg) do
      "Expected #{mu_pp(record)} to be valid, " \
      "but has the following errors:\n" +
        mu_pp(record.errors.full_messages.join("\n"))
    end

    assert_predicate record, :valid?, msg
  end

  # Asserts that the given active model record is not valid.
  # If you provide a set of invalid attribute symbols, all of and only these
  # attributes are expected to have errors. If no invalid attributes are
  # specified, only the invalidity of the record is asserted.
  def assert_not_valid(record, *invalid_attrs)
    msg = message do
      "Expected #{mu_pp(record)} to be invalid, but is valid."
    end

    assert_not record.valid?, msg

    return if invalid_attrs.blank?

    assert_invalid_attrs_have_errors(record, *invalid_attrs)
    assert_other_attrs_have_no_errors(record, *invalid_attrs)
  end

  def assert_error_message(record, attr, message)
    msg = message do
      "Expected #{mu_pp(record)} to have error message on attribute #{attr}."
    end

    assert record.errors.messages[attr.to_sym].any? { |m| message =~ m }, msg
  end

  def assert_change(expression, message = nil, &block)
    expressions = Array(expression)

    exps = expressions.map do |e|
      e.respond_to?(:call) ? e : -> { eval(e, block.binding) }
    end
    before = exps.map(&:call)

    yield

    expressions.zip(exps).each_with_index do |(code, e), _i|
      error  = "#{code.inspect} didn't change"
      error  = "#{message}.\n#{error}" if message

      assert_not_equal(before, e.call, error)
    end
  end

  def assert_arrays_match(expected, actual, &block)
    transform = lambda do |array|
      block ? array.map(&block).sort : array.sort
    end

    assert_equal(transform[expected], transform[actual])
  end

  # The method used to by Test::Unit to format arguments.
  # Prints ActiveRecord objects in a simpler format.
  def mu_pp(obj)
    if obj.is_a?(ActiveRecord::Base) # :nodoc:
      obj.to_s
    else
      super
    end
  end

  private

  def assert_invalid_attrs_have_errors(record, *invalid_attrs)
    invalid_attrs.each do |a|
      msg = message do
        "Expected attribute #{mu_pp(a)} to be invalid, but is valid."
      end

      assert_predicate record.errors[a], :present?, msg
    end
  end

  def assert_other_attrs_have_no_errors(record, *invalid_attrs)
    record.errors.each do |error|
      error_attr = error.attribute
      error_msg  = error.message
      msg = message do
        "Attribute #{mu_pp(error_attr)} not declared as invalid attribute, " \
          "but has the following error(s):\n#{mu_pp(error_msg)}"
      end

      assert_includes invalid_attrs, error_attr, msg
    end
  end
end
