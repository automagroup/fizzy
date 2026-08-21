require "test_helper"

class Card::ProjectableTest < ActiveSupport::TestCase
  setup do
    Current.session = sessions(:david)
  end

  test "assigns a project and milestone" do
    card = cards(:text)
    project = projects(:website_redesign)
    milestone = milestones(:design_signoff)

    card.assign_to_project project, milestone: milestone

    assert_equal project, card.reload.project
    assert_equal milestone, card.milestone
  end

  test "allows a project without a milestone" do
    card = cards(:text)
    project = projects(:website_redesign)

    card.assign_to_project project

    assert_equal project, card.reload.project
    assert_nil card.milestone
  end

  test "rejects a project from another board" do
    card = cards(:logo)

    assert_raises ActiveRecord::RecordInvalid do
      card.assign_to_project projects(:mobile_launch)
    end
  end

  test "rejects a milestone from another project" do
    card = cards(:logo)

    assert_raises ActiveRecord::RecordInvalid do
      card.assign_to_project projects(:website_redesign), milestone: milestones(:beta_release)
    end
  end

  test "rejects a milestone without a project" do
    card = cards(:logo)

    assert_raises ActiveRecord::RecordInvalid do
      card.assign_to_project nil, milestone: milestones(:design_signoff)
    end
  end

  test "clears project assignment when board changes" do
    card = cards(:logo)

    card.update!(board: boards(:private))

    assert_nil card.reload.project
    assert_nil card.milestone
  end

  test "cannot move to a board from another account" do
    card = cards(:logo)

    assert_raises RuntimeError, "The board must belong to the card account" do
      card.move_to boards(:miltons_wish_list)
    end

    assert_equal boards(:writebook), card.reload.board
  end
end
