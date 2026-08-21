require "test_helper"

class MilestoneTest < ActiveSupport::TestCase
  test "defaults account from project" do
    milestone = projects(:website_redesign).milestones.create!(name: "New milestone", due_on: Date.new(2026, 9, 1))

    assert_equal projects(:website_redesign).account, milestone.account
  end

  test "requires name and due date" do
    milestone = Milestone.new(project: projects(:website_redesign))

    assert_not milestone.valid?
    assert milestone.errors.added?(:name, :blank)
    assert milestone.errors.added?(:due_on, :blank)
  end

  test "requires account to match project" do
    milestone = Milestone.new(
      account: accounts(:initech),
      project: projects(:website_redesign),
      name: "Wrong account",
      due_on: Date.new(2026, 9, 1)
    )

    assert_not milestone.valid?
    assert milestone.errors.added?(:account, "must match the project account")
  end

  test "can be due after its project" do
    assert_operator milestones(:post_launch_fix).due_on, :>, projects(:website_redesign).due_on
    assert milestones(:post_launch_fix).valid?
  end

  test "inherits project color" do
    assert_equal projects(:website_redesign).color, milestones(:design_signoff).color
  end

  test "destroy preserves project assignment on cards" do
    milestone = milestones(:design_signoff)
    card = cards(:logo)
    project = card.project

    assert_no_difference -> { Card.count } do
      milestone.destroy!
    end

    assert_equal project, card.reload.project
    assert_nil card.milestone
  end

  test "touches cards when the name changes" do
    milestone = milestones(:design_signoff)
    card = milestone.cards.first

    assert_changes -> { card.reload.updated_at } do
      milestone.update!(name: "Renamed milestone")
    end
  end

  test "touches the board when the due date changes" do
    milestone = milestones(:design_signoff)
    board = milestone.board

    assert_changes -> { board.reload.updated_at } do
      milestone.update!(due_on: milestone.due_on + 1.day)
    end
  end

  test "touches all board cards when destroyed" do
    milestone = milestones(:design_signoff)
    card = milestone.board.cards.where(milestone_id: nil).first

    assert_changes -> { card.reload.updated_at } do
      milestone.destroy!
    end
  end
end
