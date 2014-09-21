require 'test_helper'

class ClientTest < ActiveSupport::TestCase

  test 'client with worktimes may not be destroyed' do
    assert_no_difference('WorkItem.count') do
      assert_no_difference('Client.count') do
        clients(:puzzle).destroy
      end
    end
  end

  test 'client without worktimes is destroyed with entire structure' do
    Worktime.destroy_all
    assert_difference('WorkItem.count', -2) do
      assert_difference('Client.count', -1) do
        clients(:swisstopo).destroy
      end
    end
  end

  test 'work item is destroyed with client' do
    client = Fabricate(:client)
    assert_difference('WorkItem.count', -1) do
      assert_difference('Client.count', -1) do
        client.destroy
      end
    end
  end

end
