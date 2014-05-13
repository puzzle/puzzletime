require File.dirname(__FILE__) + '/../test_helper'

class PlanningTest < ActiveSupport::TestCase

  def test_overlapping_with_no_repeat_and_no_repeat
    p1 = build_planning(201010, 201010)
    p1.save!
    
    # test p1 with himself
    assert !p1.send(:overlaps?, p1)
    
    # test p2 after p1
    p2 = build_planning(201011, 201011)
    assert !p1.send(:overlaps?, p2)

    # test p2 before p1
    p2 = build_planning(201009, 201009)
    assert !p1.send(:overlaps?, p2)

    # test overlapping
    p2 = build_planning(201010, 201010)
    assert p1.send(:overlaps?, p2)
  end

  def test_overlapping_with_no_repeat_and_repeat_until
    p1 = build_planning(201010, 201010)
    p1.save!
    
    # test p1 with himself
    assert !p1.send(:overlaps?, p1)

    # test p2 after p1
    p2 = build_planning(201011, 201020)
    assert !p1.send(:overlaps?, p2)

    # test p2 before p1
    p2 = build_planning(201001, 201009)
    assert !p1.send(:overlaps?, p2)

    # test overlapping
    p2 = build_planning(201001, 201020)
    assert p1.send(:overlaps?, p2)
  end

  def test_overlapping_with_no_repeat_and_repeat_forever
    p1 = build_planning(201010, 201010)
    p1.save!
    
    # test p1 with himself
    assert !p1.send(:overlaps?, p1)

    # test p2 after p1
    p2 = build_planning(201011, nil)
    assert !p1.send(:overlaps?, p2)

    # test p2 before p1
    p2 = build_planning(201001, nil)
    assert p1.send(:overlaps?, p2)
  end

  def test_overlapping_with_repeat_until_and_no_repeat
    p1 = build_planning(201010, 201020)
    p1.save!
    
    # test p1 with himself
    assert !p1.send(:overlaps?, p1)
    
    # test p2 after p1
    p2 = build_planning(201021, 201021)
    assert !p1.send(:overlaps?, p2)

    # test p2 before p1
    p2 = build_planning(201009, 201009)
    assert !p1.send(:overlaps?, p2)

    # test overlapping
    p2 = build_planning(201015, 201015)
    assert p1.send(:overlaps?, p2)
  end

  def test_overlapping_with_repeat_until_and_repeat_until
    p1 = build_planning(201010, 201020)
    p1.save!
    
    # test p1 with himself
    assert !p1.send(:overlaps?, p1)
    
    # test p2 after p1
    p2 = build_planning(201021, 201031)
    assert !p1.send(:overlaps?, p2)

    # test p2 before p1
    p2 = build_planning(201001, 201009)
    assert !p1.send(:overlaps?, p2)

    # test overlapping
    p2 = build_planning(201005, 201015)
    assert p1.send(:overlaps?, p2)
  end

  def test_overlapping_with_repeat_until_and_repeat_forever
    p1 = build_planning(201010, 201020)
    p1.save!
    
    # test p1 with himself
    assert !p1.send(:overlaps?, p1)
    
    # test p2 after p1
    p2 = build_planning(201021, nil)
    assert !p1.send(:overlaps?, p2)

    # test p2 before p1
    p2 = build_planning(201001, nil)
    assert p1.send(:overlaps?, p2)
  end

  def test_overlapping_with_repeat_forever_and_no_repeat
    p1 = build_planning(201010, nil)
    p1.save!
    
    # test p1 with himself
    assert !p1.send(:overlaps?, p1)
    
    # test p2 after p1
    p2 = build_planning(201011, 201011)
    assert p1.send(:overlaps?, p2)

    # test p2 before p1
    p2 = build_planning(201009, 201009)
    assert !p1.send(:overlaps?, p2)
  end

  def test_overlapping_with_repeat_forever_and_repeat_until
    p1 = build_planning(201010, nil)
    p1.save!
    
    # test p1 with himself
    assert !p1.send(:overlaps?, p1)
    
    # test p2 after p1
    p2 = build_planning(201011, 201020)
    assert p1.send(:overlaps?, p2)

    # test p2 before p1
    p2 = build_planning(201001, 201009)
    assert !p1.send(:overlaps?, p2)
  end

  def test_overlapping_with_repeat_forever_and_repeat_forever
    p1 = build_planning(201010, nil)
    p1.save!
    
    # test p1 with himself
    assert !p1.send(:overlaps?, p1)
    
    # test p2 after p1
    p2 = build_planning(201011, nil)
    assert p1.send(:overlaps?, p2)

    # test p2 before p1
    p2 = build_planning(201001, nil)
    assert p1.send(:overlaps?, p2)
  end


private
  def build_planning(start_week, end_week)
    Planning.new(:start_week => start_week,
                 :end_week => end_week,
                 :monday_am => true, 
                 :employee_id => employees(:long_time_john),
                 :project_id => projects(:allgemein))
  end
  
end
