require "test_helper"

class Cards::PublishesControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in_as :kevin
  end

  test "create" do
    card = cards(:text)
    card.drafted!

    assert_changes -> { card.reload.published? }, from: false, to: true do
      post card_publish_path(card)
    end

    assert_redirected_to card.board
  end

  test "create in a project returns to the project" do
    card = cards(:logo)
    card.update!(status: :drafted, column: nil)

    assert_changes -> { card.reload.published? }, from: false, to: true do
      post card_publish_path(card)
    end

    assert_redirected_to board_project_path(card.board, card.project)
    assert card.reload.awaiting_triage?
  end

  test "create as JSON" do
    card = cards(:logo)
    card.drafted!

    assert_changes -> { card.reload.published? }, from: false, to: true do
      post card_publish_path(card), as: :json
    end

    assert_response :created
  end

  test "create and add another" do
    card = cards(:logo)
    card.drafted!

    assert_changes -> { card.reload.published? }, from: false, to: true do
      assert_difference -> { Card.count }, +1 do
        post card_publish_path(card, creation_type: "add_another")
      end
    end

    new_card = Card.last
    assert new_card.drafted?
    assert_equal card.project, new_card.project
    assert_equal card.milestone, new_card.milestone
    assert_redirected_to card_draft_path(new_card)
  end
end
