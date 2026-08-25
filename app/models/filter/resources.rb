module Filter::Resources
  extend ActiveSupport::Concern

  included do
    has_and_belongs_to_many :tags
    has_and_belongs_to_many :boards
    has_and_belongs_to_many :projects
    has_and_belongs_to_many :assignees, class_name: "User", join_table: "assignees_filters", association_foreign_key: "assignee_id"
    has_and_belongs_to_many :creators, class_name: "User", join_table: "creators_filters", association_foreign_key: "creator_id"
    has_and_belongs_to_many :closers, class_name: "User", join_table: "closers_filters", association_foreign_key: "closer_id"

    before_validation :assign_accessible_projects
  end

  def resource_removed(resource)
    kind = resource.class.model_name.plural
    association(kind.to_sym).delete(resource)
    @as_params = @boards = nil
    @projects = nil if kind == "projects"
    empty? ? destroy! : save!
  rescue ActiveRecord::RecordNotUnique
    destroy!
  end

  def boards
    @boards ||= creator.boards.where id: super.ids
  end

  def project_ids=(ids)
    @pending_project_ids = Array(ids).compact_blank
  end

  def project_ids
    assign_accessible_projects
    super
  end

  def projects
    @projects ||= accessible_projects(project_ids)
  end

  def filtering_by_projects?
    project_ids.any?
  end

  def board_titles
    if boards.none?
      creator.boards.one? ? [ creator.boards.first.name ] : [ "all boards" ]
    else
      boards.map(&:name)
    end
  end

  def boards_label
    board_titles.to_sentence
  end

  private
    def assign_accessible_projects
      if @pending_project_ids
        self.projects = accessible_projects(@pending_project_ids)
        @pending_project_ids = nil
        @projects = nil
      end
    end

    def accessible_projects(ids)
      Project.where(board: creator.boards, id: ids)
    end
end
