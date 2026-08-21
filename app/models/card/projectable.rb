module Card::Projectable
  extend ActiveSupport::Concern

  included do
    belongs_to :project, optional: true
    belongs_to :milestone, optional: true

    before_validation :clear_project_assignment, if: :moving_between_boards?

    validate :project_matches_board_and_account
    validate :milestone_matches_project_and_account
  end

  def assign_to_project(project, milestone: nil)
    update!(project: project, milestone: milestone)
  end

  private
    def moving_between_boards?
      persisted? && will_save_change_to_board_id?
    end

    def clear_project_assignment
      self.project = nil
      self.milestone = nil
    end

    def project_matches_board_and_account
      if project && project.board != board
        errors.add :project, "must belong to the card board"
      end

      if project && project.account != account
        errors.add :project, "must belong to the card account"
      end
    end

    def milestone_matches_project_and_account
      if milestone && project.nil?
        errors.add :milestone, "requires a project"
      elsif milestone && milestone.project != project
        errors.add :milestone, "must belong to the card project"
      end

      if milestone && milestone.account != account
        errors.add :milestone, "must belong to the card account"
      end
    end
end
