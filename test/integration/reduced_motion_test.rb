# frozen_string_literal: true

#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

require 'test_helper'

# Guards the two halves of the animation-determinism setup. Without both, CSS
# transitions keep moving elements after Capybara has computed a click's
# coordinates, and clicks silently land on stale positions — which shows up as
# unrelated integration tests flaking rather than as a failure here.
class ReducedMotionTest < ActionDispatch::IntegrationTest
  setup do
    login_as(:mark)
    visit root_path
  end

  test 'chrome reports the reduce-motion preference' do
    assert page.evaluate_script("window.matchMedia('(prefers-reduced-motion: reduce)').matches"),
           'Chrome is not reporting prefers-reduced-motion. Check the ' \
           "'force-prefers-reduced-motion' browser option in test_helper.rb."
  end

  test 'stylesheet collapses transition durations' do
    seconds = page.evaluate_script(<<~JS)
      (function () {
        var el = document.createElement('div');
        el.style.transition = 'opacity 2s linear';
        document.body.appendChild(el);
        var value = getComputedStyle(el).transitionDuration;
        el.remove();
        return parseFloat(value);
      })()
    JS

    assert_operator seconds, :<, 0.05,
                    'A 2s transition was not collapsed. Check the ' \
                    'prefers-reduced-motion block in puzzletime.scss.'
  end
end
