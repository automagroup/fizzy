require "test_helper"

class Boards::Projects::MilestonesControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in_as :jz
  end

  test "show opens the project panel at the selected milestone" do
    get board_project_milestone_path(boards(:writebook), projects(:website_redesign), milestones(:design_signoff))

    assert_response :success
    assert_select "##{dom_id(milestones(:design_signoff))}.project-card-group--selected[data-scroll-to-target=target]"
    assert_select ".project-panel__title", text: projects(:website_redesign).name
  end

  test "new and edit render milestone forms" do
    get new_board_project_milestone_path(boards(:writebook), projects(:website_redesign))
    assert_response :success
    assert_select "form[action=?]", board_project_milestones_path(boards(:writebook), projects(:website_redesign))
    assert_select "input[type=date][name='milestone[due_on]']"

    get edit_board_project_milestone_path(boards(:writebook), projects(:website_redesign), milestones(:design_signoff))
    assert_response :success
    assert_select "form[action=?]", board_project_milestone_path(boards(:writebook), projects(:website_redesign), milestones(:design_signoff))
  end

  test "member creates milestone" do
    assert_difference -> { projects(:website_redesign).milestones.count }, +1 do
      post board_project_milestones_path(boards(:writebook), projects(:website_redesign)), params: {
        milestone: {
          name: "Content ready",
          due_on: "2026-09-10"
        }
      }
    end

    milestone = projects(:website_redesign).milestones.order(:created_at).last
    assert_redirected_to board_project_milestone_path(boards(:writebook), projects(:website_redesign), milestone)
  end

  test "owner without board access cannot create milestone" do
    logout_and_sign_in_as :jason

    assert_no_difference -> { Milestone.count } do
      post board_project_milestones_path(boards(:writebook), projects(:website_redesign)), params: {
        milestone: {
          name: "Content ready",
          due_on: "2026-09-10"
        }
      }
    end

    assert_response :not_found
  end

  test "cannot use a project from another board" do
    logout_and_sign_in_as :kevin

    post board_project_milestones_path(boards(:private), projects(:website_redesign)), params: {
      milestone: {
        name: "Content ready",
        due_on: "2026-09-10"
      }
    }

    assert_response :not_found
  end

  test "member updates milestone" do
    patch board_project_milestone_path(boards(:writebook), projects(:website_redesign), milestones(:design_signoff)), params: {
      milestone: {
        name: "Design approved",
        due_on: "2026-08-25"
      }
    }

    assert_redirected_to board_project_milestone_path(boards(:writebook), projects(:website_redesign), milestones(:design_signoff))
    assert_equal "Design approved", milestones(:design_signoff).reload.name
  end

  test "member deletes milestone without deleting cards" do
    assert_no_difference -> { Card.count } do
      assert_difference -> { Milestone.count }, -1 do
        delete board_project_milestone_path(boards(:writebook), projects(:website_redesign), milestones(:design_signoff))
      end
    end

    assert_redirected_to board_project_path(boards(:writebook), projects(:website_redesign))
  end
end
