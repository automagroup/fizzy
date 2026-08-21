require "application_system_test_case"

class ProjectsAndCalendarTest < ApplicationSystemTestCase
  test "navigating projects and calendar keeps the panel in browser history" do
    board = boards(:writebook)
    project = projects(:website_redesign)
    milestone = milestones(:design_signoff)
    sign_in_as(users(:kevin))

    visit board_url(board)
    within ".board-navigation" do
      click_on "Projects"
    end

    assert_current_path board_projects_path(board)
    assert_selector ".board-navigation__link[aria-current='page']", text: "Projects"

    within ".project-list" do
      click_on project.name
    end

    assert_current_path board_project_path(board, project)
    assert_selector "dialog.project-panel[open]"
    within "turbo-frame#project_panel" do
      assert_selector ".project-panel__title", text: project.name
      assert_text "Design sign-off"
      find("button[title='Close project']").click
    end

    assert_current_path board_projects_path(board)
    assert_no_selector "dialog.project-panel[open]"

    calendar_url = board_calendar_url(board, month: "2026-08")
    visit calendar_url
    find(".calendar-event--milestone", text: milestone.name).click

    assert_current_path board_project_milestone_path(board, project, milestone)
    assert_selector "dialog.project-panel[open]"
    assert_selector "##{dom_id(milestone)}.project-card-group--selected"
    find("button[title='Close project']").click

    assert_current_path calendar_url, ignore_query: false
  end

  test "a direct project URL closes back to the projects list" do
    board = boards(:writebook)
    project = projects(:website_redesign)
    sign_in_as(users(:kevin))

    visit board_project_url(board, project)

    assert_selector "dialog.project-panel[open]"
    assert_selector ".project-panel__title", text: project.name
    find("button[title='Close project']").click

    assert_current_path board_projects_path(board)
    assert_no_selector "dialog.project-panel[open]"
  end

  test "the edit close control returns to project details while cancel closes the panel" do
    board = boards(:writebook)
    project = projects(:website_redesign)
    sign_in_as(users(:kevin))

    visit board_projects_url(board)
    within ".project-list" do
      click_on project.name
    end

    find("a[title='Edit project']").click
    find("a[title='Back to project details']").click

    assert_current_path board_project_path(board, project)
    assert_selector "dialog.project-panel[open]"
    assert_no_selector "form.project-form"
    assert_selector ".project-panel__title", text: project.name

    find("a[title='Edit project']").click
    within "form.project-form" do
      click_on "Cancel"
    end

    assert_current_path board_projects_path(board)
    assert_no_selector "dialog.project-panel[open]"
  end

  test "the edit close control returns to project details from a direct URL" do
    board = boards(:writebook)
    project = projects(:website_redesign)
    sign_in_as(users(:kevin))

    visit edit_board_project_url(board, project)
    find("a[title='Back to project details']").click

    assert_current_path board_project_path(board, project)
    assert_selector "dialog.project-panel[open]"
    assert_no_selector "form.project-form"
    assert_selector ".project-panel__title", text: project.name
  end

  test "the milestone edit close control returns to project details while cancel closes the panel" do
    board = boards(:writebook)
    project = projects(:website_redesign)
    milestone = milestones(:design_signoff)
    sign_in_as(users(:kevin))

    visit board_projects_url(board)
    within ".project-list" do
      click_on project.name
    end

    find("a[title='Edit #{milestone.name}']").click
    find("a[title='Back to project details']").click

    assert_current_path board_project_milestone_path(board, project, milestone)
    assert_selector "dialog.project-panel[open]"
    assert_no_selector "form.project-form"
    assert_selector "##{dom_id(milestone)}.project-card-group--selected"

    find("a[title='Edit #{milestone.name}']").click
    within "form.project-form" do
      click_on "Cancel"
    end

    assert_current_path board_projects_path(board)
    assert_no_selector "dialog.project-panel[open]"
  end

  test "the milestone edit close control returns to project details from a direct URL" do
    board = boards(:writebook)
    project = projects(:website_redesign)
    milestone = milestones(:design_signoff)
    sign_in_as(users(:kevin))

    visit edit_board_project_milestone_url(board, project, milestone)
    find("a[title='Back to project details']").click

    assert_current_path board_project_milestone_path(board, project, milestone)
    assert_selector "dialog.project-panel[open]"
    assert_no_selector "form.project-form"
    assert_selector "##{dom_id(milestone)}.project-card-group--selected"
  end

  test "a board member creates a project and milestone from the panel" do
    board = boards(:writebook)
    sign_in_as(users(:jz))

    visit board_projects_url(board)
    click_on "New project"

    assert_selector "dialog.project-panel[open]"
    within "form.project-form" do
      fill_in "Name", with: "Launch campaign"
      set_date "project_due_on", "2026-10-15"
      click_on "Create project"
    end

    assert_selector ".project-panel__title", text: "Launch campaign"
    project = board.projects.find_by!(name: "Launch campaign")
    assert_current_path board_project_path(board, project)
    assert_equal Date.new(2026, 10, 15), project.due_on

    click_on "Milestone"
    within "form.project-form" do
      fill_in "Name", with: "Press preview"
      set_date "milestone_due_on", "2026-10-20"
      click_on "Create milestone"
    end

    assert_selector ".project-card-group--selected", text: "Press preview"
    milestone = project.milestones.find_by!(name: "Press preview")
    assert_current_path board_project_milestone_path(board, project, milestone)
    assert_selector "##{dom_id(milestone)}.project-card-group--selected", text: milestone.name
    assert_equal Date.new(2026, 10, 20), milestone.due_on
  end

  test "projects and calendar stay usable at a narrow viewport" do
    board = boards(:writebook)
    project = projects(:website_redesign)
    sign_in_as(users(:kevin))

    page.driver.browser.manage.window.resize_to(390, 844)
    assert page.evaluate_script("matchMedia('(max-width: 639px)').matches")

    visit board_projects_url(board)
    within ".project-list" do
      click_on project.name
    end
    assert_selector "dialog.project-panel[open]"

    dialog_width = page.evaluate_script("document.querySelector('dialog.project-panel').getBoundingClientRect().width")
    viewport_width = page.evaluate_script("window.innerWidth")
    assert_in_delta viewport_width, dialog_width, 1

    visit board_calendar_url(board, month: "2026-08")
    assert_selector ".calendar-grid-container"
    assert page.evaluate_script(<<~JS)
      (() => {
        const calendar = document.querySelector('.calendar-grid-container')
        return calendar.scrollWidth > calendar.clientWidth
      })()
    JS
  ensure
    page.driver.browser.manage.window.resize_to(1200, 1000)
  end

  private
    def set_date(field_id, value)
      page.execute_script(<<~JS)
        (() => {
          const field = document.getElementById('#{field_id}')
          field.value = '#{value}'
          field.dispatchEvent(new Event('input', { bubbles: true }))
          field.dispatchEvent(new Event('change', { bubbles: true }))
        })()
      JS
    end
end
