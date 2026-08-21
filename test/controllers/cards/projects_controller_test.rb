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
