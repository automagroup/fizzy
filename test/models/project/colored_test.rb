require "test_helper"

class Project::ColoredTest < ActiveSupport::TestCase
  test "uses the default palette color" do
    project = boards(:writebook).projects.create!(name: "New project", due_on: Date.new(2026, 9, 1))

    assert_equal Project::Colored::DEFAULT_COLOR, project.color
  end

  test "accepts colors from the Fizzy palette" do
    project = projects(:website_redesign)

    project.update!(color: "var(--color-card-3)")

    assert_equal Color.for_value("var(--color-card-3)"), project.color
  end

  test "rejects colors outside the Fizzy palette" do
    project = projects(:website_redesign)

    project.color = "#ff0000"

    assert_not project.valid?
    assert project.errors.added?(:color, "is not in the palette")
  end
end
