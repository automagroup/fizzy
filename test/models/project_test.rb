require "test_helper"

class ProjectTest < ActiveSupport::TestCase
  test "defaults account from board" do
    project = boards(:writebook).projects.create!(name: "New project", due_on: Date.new(2026, 9, 1))

    assert_equal boards(:writebook).account, project.account
  end

  test "requires name and due date" do
    project = Project.new(board: boards(:writebook))

    assert_not project.valid?
    assert project.errors.added?(:name, :blank)
    assert project.errors.added?(:due_on, :blank)
  end

  test "requires account to match board" do
    project = Project.new(
      account: accounts(:initech),
      board: boards(:writebook),
      name: "Wrong account",
      due_on: Date.new(2026, 9, 1)
    )

    assert_not project.valid?
    assert project.errors.added?(:account, "must match the board account")
  end

  test "orders by due date and name" do
    project = projects(:website_redesign)
    same_day = project.board.projects.create!(name: "Alpha", due_on: project.due_on)

    assert_equal [ same_day, project ], project.board.projects.chronologically.where(id: [ project.id, same_day.id ])
  end

  test "destroy preserves cards and clears project and milestone" do
    project = projects(:website_redesign)
    card = cards(:logo)

    assert_no_difference -> { Card.count } do
      project.destroy!
    end

    assert_nil card.reload.project
    assert_nil card.milestone
  end

  test "touches cards when name or color changes" do
    project = projects(:website_redesign)
    card = project.cards.first

    assert_changes -> { card.reload.updated_at } do
      project.update!(name: "Renamed project")
    end

    assert_changes -> { card.reload.updated_at } do
      project.update!(color: "var(--color-card-7)")
    end
  end

  test "touches the board when the due date changes" do
    project = projects(:website_redesign)
    board = project.board

    assert_changes -> { board.reload.updated_at } do
      project.update!(due_on: project.due_on + 1.day)
    end
  end

  test "touches all board cards when destroyed" do
    project = projects(:website_redesign)
    card = project.board.cards.where(project_id: nil).first

    assert_changes -> { card.reload.updated_at } do
      project.destroy!
    end
  end
end
