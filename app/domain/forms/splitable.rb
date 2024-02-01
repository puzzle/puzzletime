#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

class Forms::Splitable
  class_attribute :incomplete_finish
  self.incomplete_finish = true

  attr_reader :original, :original_id, :worktimes

  def initialize(original)
    @original = original.dup
    @original_id = original.id
    @worktimes = []
  end

  def add_worktime(worktime)
    @worktimes.push(worktime)
  end

  def remove_worktime(index)
    @worktimes.delete_at(index) if @worktimes[index].new_record?
  end

  def build_worktime
    Ordertime.new
  end

  def worktime_template
    worktime = last_worktime.template Ordertime.new
    worktime.hours = remaining_hours
    worktime.from_start_time = next_start_time
    worktime.to_end_time = original.to_end_time if next_start_time
    worktime
  end

  def complete?
    remaining_hours < 0.00001 # we are working with floats: use delta
  end

  def save
    Worktime.transaction do
      worktimes.each(&:save!)
    end
  end

  def page_title
    'Aufteilen'
  end

  delegate :empty?, to: :worktimes

  protected

  def remaining_hours
    original.hours - worktimes.inject(0) { |sum, time| sum + time.hours }
  end

  def next_start_time
    empty? ? original.from_start_time : worktimes.last.to_end_time
  end

  def last_worktime
    empty? ? original : worktimes.last
  end
end
