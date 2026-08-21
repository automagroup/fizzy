class Boards::ProjectsController < ApplicationController
  include BoardScoped

  before_action :set_project, only: %i[ show edit update destroy ]

  def index
    @projects = @board.projects.chronologically.load
    project_ids = @projects.map(&:id)

    @open_card_counts = @board.cards.published.open.where(project_id: project_ids).group(:project_id).count
    @closed_card_counts = @board.cards.published.closed.where(project_id: project_ids).group(:project_id).count
    @milestone_counts = @board.milestones.where(project_id: project_ids).group(:project_id).count
  end

  def show
    set_project_panel
  end

  def new
    @project = @board.projects.new
  end

  def create
    @project = @board.projects.create!(project_params)
    redirect_to board_project_path(@board, @project), notice: "Project created"
  end

  def edit
  end

  def update
    @project.update!(project_params)
    redirect_to board_project_path(@board, @project), notice: "Project saved"
  end

  def destroy
    @project.destroy!
    redirect_to board_projects_path(@board), notice: "Project deleted"
  end

  private
    def set_project
      @project = @board.projects.find(params[:id])
    end

    def set_project_panel
      @milestones = @project.milestones.chronologically.load
      @project_cards = @project.cards.published.preloaded.to_a
    end

    def project_params
      params.expect(project: [ :name, :due_on, :color ])
    end
end
