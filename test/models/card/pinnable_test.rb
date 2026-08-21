require "test_helper"

class Card::PinnableTest < ActiveSupport::TestCase
  setup do
    Current.session = sessions(:david)
  end

  test "broadcasts pin update when title changes" do
    assert_broadcasted_pin_update do
      cards(:logo).update!(title: "New title")
    end
  end

  test "broadcasts pin update when column changes" do
    assert_broadcasted_pin_update do
      cards(:logo).update!(column: columns(:writebook_in_progress))
    end
  end

  test "broadcasts pin update when board changes" do
    assert_broadcasted_pin_update do
      cards(:logo).update!(board: boards(:private), column: nil)
    end
  end

  test "broadcasts pin update when project changes" do
    project = boards(:writebook).projects.create!(name: "Another project", due_on: Date.new(2026, 9, 1))

    assert_broadcasted_pin_update do
      cards(:logo).update!(project: project, milestone: nil)
    end
  end

  test "broadcasts pin update when milestone changes" do
    assert_broadcasted_pin_update do
      cards(:logo).update!(milestone: milestones(:post_launch_fix))
    end
  end

  test "does not broadcast pin update when other properties change" do
    perform_enqueued_jobs do
      assert_turbo_stream_broadcasts([ pins(:logo_kevin).user, :pins_tray ], count: 0) do
        cards(:logo).update!(last_active_at: Time.current)
      end
    end
  end

  private
    def assert_broadcasted_pin_update(&block)
      perform_enqueued_jobs do
        assert_turbo_stream_broadcasts([ pins(:logo_kevin).user, :pins_tray ], &block)
      end
    end
end
