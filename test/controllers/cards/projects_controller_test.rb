require "test_helper"

class Cards::ProjectsControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in_as :jz
  end

  test "edit lists project and milestone destinations" do
    get edit_card_project_path(cards(:text))

    assert_response :success
    assert_select ".card-project-picker__project-name", text: projects(:website_redesign).name
    assert_select ".card-project-picker__destination" do |destinations|
      assert destinations.any? { |destination| destination.text.include?(milestones(:design_signoff).name) }
    end
    assert_select ".card-project-picker form" do |forms|
      assert forms.all? { |form| form["data-turbo"] == "false" }
    end
  end

  test "edit renders project picker in a turbo frame" do
    card = cards(:logo)

    get edit_card_project_path(card), headers: { "Turbo-Frame" => dom_id(card, :project_picker) }

    assert_response :success
    assert_select "turbo-frame##{dom_id(card, :project_picker)}" do
      assert_select "[data-controller~='filter'][data-controller~='navigable-list']"
      assert_select ".popup__title[data-dialog-target=focusTouch]", text: "Move this card to…"
      assert_select "kbd", text: "r"
      assert_select "input[type=search][data-filter-target=input][data-dialog-target=focusMouse][aria-label='Filter projects and milestones']"
      assert_select ".popup__list[role=radiogroup][aria-label='Project destinations']"
      assert_select ".popup__item[role=radio][data-navigable-list-target=item][aria-checked=true]", text: /#{Regexp.escape(card.milestone.name)}/
      assert_select ".popup__item[role=radio][data-navigable-list-target=item]", text: /#{Regexp.escape(projects(:website_redesign).name)}/
      assert_select ".popup__item[role=radio][data-navigable-list-target=item]", text: /#{Regexp.escape(milestones(:design_signoff).name)}/
      assert_select "button.popup__btn[title=?]", "#{projects(:website_redesign).name} — No milestone"
      assert_select "button.popup__btn[title=?]", "#{projects(:website_redesign).name} — #{milestones(:design_signoff).name}"
    end
  end

  test "member assigns card to project and milestone" do
    patch card_project_path(cards(:text)), params: {
      card: {
        project_id: projects(:website_redesign).id,
        milestone_id: milestones(:design_signoff).id
      }
    }

    assert_redirected_to card_path(cards(:text))
    assert_equal projects(:website_redesign), cards(:text).reload.project
    assert_equal milestones(:design_signoff), cards(:text).milestone
  end

  test "member assigns card to project and milestone with turbo stream" do
    card = cards(:text)

    patch card_project_path(card, format: :turbo_stream), params: {
      card: {
        project_id: projects(:website_redesign).id,
        milestone_id: milestones(:design_signoff).id
      }
    }

    assert_response :success
    assert_equal projects(:website_redesign), card.reload.project
    assert_equal milestones(:design_signoff), card.milestone
    assert_select "turbo-stream[action=replace][target=?]", dom_id(card, :project_badges)
  end

  test "member assigns card without milestone" do
    patch card_project_path(cards(:text)), params: {
      card: {
        project_id: projects(:website_redesign).id,
        milestone_id: ""
      }
    }

    assert_equal projects(:website_redesign), cards(:text).reload.project
    assert_nil cards(:text).milestone
  end

  test "member moves card to another project on the same board" do
    other_project = boards(:writebook).projects.create!(name: "Other project", due_on: Date.new(2026, 10, 1))

    patch card_project_path(cards(:logo)), params: {
      card: {
        project_id: other_project.id,
        milestone_id: ""
      }
    }

    assert_equal other_project, cards(:logo).reload.project
    assert_nil cards(:logo).milestone
  end

  test "cannot assign project from another board" do
    patch card_project_path(cards(:text)), params: {
      card: {
        project_id: projects(:mobile_launch).id,
        milestone_id: ""
      }
    }

    assert_response :not_found
  end

  test "cannot assign milestone from another project" do
    patch card_project_path(cards(:text)), params: {
      card: {
        project_id: projects(:website_redesign).id,
        milestone_id: milestones(:beta_release).id
      }
    }

    assert_response :not_found
  end

  test "member removes project assignment" do
    delete card_project_path(cards(:logo))

    assert_redirected_to card_path(cards(:logo))
    assert_nil cards(:logo).reload.project
    assert_nil cards(:logo).milestone
  end

  test "member removes project assignment with turbo stream" do
    card = cards(:logo)

    delete card_project_path(card, format: :turbo_stream)

    assert_response :success
    assert_nil card.reload.project
    assert_nil card.milestone
    assert_select "turbo-stream[action=replace][target=?]", dom_id(card, :project_badges)
  end

  test "user without card access cannot update project" do
    boards(:writebook).update!(all_access: false)
    boards(:writebook).accesses.revoke_from users(:jz)

    patch card_project_path(cards(:text)), params: {
      card: {
        project_id: projects(:website_redesign).id,
        milestone_id: ""
      }
    }

    assert_response :not_found
  end
end
