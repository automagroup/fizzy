require "test_helper"

class Boards::ProjectsControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in_as :jz
  end

  test "index lists projects with counts and panel host" do
    get board_projects_path(boards(:writebook))

    assert_response :success
    assert_select ".board-navigation__link[aria-current=page]", text: "Projects"
    assert_select ".project-list__item", count: 1
    assert_select ".project-list__name", text: "Website redesign"
    assert_select ".project-list__counts", text: /2 open.*1 done.*2 milestones/m
    assert_select "a", text: /New project/
    assert_select "turbo-frame#project_panel"
  end

  test "show renders cards grouped in the project panel" do
    get board_project_path(boards(:writebook), projects(:website_redesign))

    assert_response :success
    assert_select ".project-panel__title", text: "Website redesign"
    assert_select "##{dom_id(milestones(:design_signoff))} .project-panel-card__title", text: cards(:logo).title
    assert_select "##{dom_id(projects(:website_redesign), :no_milestone)} .project-panel-card__title", text: cards(:layout).title
    assert_select ".project-panel__done:not([open]) .project-panel-card__title", text: cards(:shipping).title
    assert_select "a[title='Edit project']"
    assert_select "a[title=?]", "Edit #{milestones(:design_signoff).name}"
    assert_select "a", text: /Milestone/
    assert_select ".project-card-group__actions button", text: /New card/, minimum: 1
  end

  test "new and edit render project forms" do
    get new_board_project_path(boards(:writebook))
    assert_response :success
    assert_select "form[action=?]", board_projects_path(boards(:writebook))
    assert_select "input[type=date][name='project[due_on]']"
    assert_select "input[type=radio][name='project[color]']", count: Color::COLORS.size

    get edit_board_project_path(boards(:writebook), projects(:website_redesign))
    assert_response :success
    assert_select "form[action=?]", board_project_path(boards(:writebook), projects(:website_redesign))
  end

  test "member creates project on an accessible board" do
    assert_difference -> { boards(:writebook).projects.count }, +1 do
      post board_projects_path(boards(:writebook)), params: {
        project: {
          name: "Launch campaign",
          due_on: "2026-09-30",
          color: "var(--color-card-3)"
        }
      }
    end

    project = boards(:writebook).projects.order(:created_at).last
    assert_redirected_to board_project_path(boards(:writebook), project)
  end

  test "owner without board access cannot create project" do
    logout_and_sign_in_as :jason

    assert_no_difference -> { Project.count } do
      post board_projects_path(boards(:writebook)), params: {
        project: {
          name: "Launch campaign",
          due_on: "2026-09-30",
          color: "var(--color-card-3)"
        }
      }
    end

    assert_response :not_found
  end

  test "member updates project" do
    patch board_project_path(boards(:writebook), projects(:website_redesign)), params: {
      project: {
        name: "Updated website",
        due_on: "2026-10-01",
        color: "var(--color-card-7)"
      }
    }

    assert_redirected_to board_project_path(boards(:writebook), projects(:website_redesign))
    assert_equal "Updated website", projects(:website_redesign).reload.name
  end

  test "cannot update project through another board" do
    logout_and_sign_in_as :kevin

    patch board_project_path(boards(:private), projects(:website_redesign)), params: {
      project: {
        name: "Updated website",
        due_on: "2026-10-01",
        color: "var(--color-card-7)"
      }
    }

    assert_response :not_found
  end

  test "member deletes project without deleting cards" do
    assert_no_difference -> { Card.count } do
      assert_difference -> { Project.count }, -1 do
        delete board_project_path(boards(:writebook), projects(:website_redesign))
      end
    end

    assert_redirected_to board_projects_path(boards(:writebook))
  end
end
