require "test_helper"

class Boards::CalendarsControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in_as :kevin
  end

  test "show renders a Sunday-first month with projects and milestones" do
    get board_calendar_path(boards(:writebook), month: "2026-08")

    assert_response :success
    assert_select ".board-navigation__link[aria-current=page]", text: "Calendar"
    assert_select "#calendar_month_heading", text: "August 2026"
    assert_select ".calendar-grid thead th:first-child", text: "Sun"
    assert_select ".calendar-grid thead th:last-child", text: "Sat"
    assert_select ".calendar-day", count: 42
    assert_select ".calendar-grid tbody tr:first-child .calendar-day:first-child[data-date='2026-07-26']"
    assert_select ".calendar-grid tbody tr:last-child .calendar-day:last-child[data-date='2026-09-05']"
    assert_select ".calendar-event--project", text: projects(:website_redesign).name
    assert_select ".calendar-event--milestone[title='Website redesign: Design sign-off']", text: milestones(:design_signoff).name
    assert_select ".calendar-event", text: cards(:logo).title, count: 0
    assert_select "turbo-frame#project_panel"
  end

  test "show only includes deliveries in the requested month" do
    get board_calendar_path(boards(:writebook), month: "2026-09")

    assert_response :success
    assert_select ".calendar-event--project", text: projects(:website_redesign).name, count: 0
    assert_select ".calendar-event--milestone", text: milestones(:post_launch_fix).name
    assert_select ".calendar-event--milestone", text: milestones(:design_signoff).name, count: 0
  end

  test "show defaults to the current month" do
    travel_to Date.new(2026, 8, 21) do
      get board_calendar_path(boards(:writebook))

      assert_response :success
      assert_select "#calendar_month_heading", text: "August 2026"
      assert_select ".calendar-day--today[data-date='2026-08-21']"
    end
  end

  test "invalid month redirects to the current month" do
    travel_to Date.new(2026, 8, 21) do
      get board_calendar_path(boards(:writebook), month: "2026-13")

      assert_redirected_to board_calendar_path(boards(:writebook), month: "2026-08")
    end
  end

  test "user without board access cannot see calendar" do
    logout_and_sign_in_as :jason

    get board_calendar_path(boards(:writebook), month: "2026-08")

    assert_response :not_found
  end
end
