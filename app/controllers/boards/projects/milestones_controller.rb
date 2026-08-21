class Boards::Projects::MilestonesController < ApplicationController
  include BoardScoped

  before_action :set_project
  before_action :set_milestone, only: %i[ show edit update destroy ]

  def show
    @selected_milestone = @milestone
    @milestones = @project.milestones.chronologically.load
    @project_cards = @project.cards.published.preloaded.to_a
  end

  def new
    @milestone = @project.milestones.new
  end

  def create
    @milestone = @project.milestones.create!(milestone_params)
    redirect_to board_project_milestone_path(@board, @project, @milestone), notice: "Milestone created"
  end

  def edit
  end

  def update
    @milestone.update!(milestone_params)
    redirect_to board_project_milestone_path(@board, @project, @milestone), notice: "Milestone saved"
  end

  def destroy
    @milestone.destroy!
    redirect_to board_project_path(@board, @project), notice: "Milestone deleted"
  end

  private
    def set_project
      @project = @board.projects.find(params[:project_id])
    end

    def set_milestone
      @milestone = @project.milestones.find(params[:id])
    end

    def milestone_params
      params.expect(milestone: [ :name, :due_on ])
    end
end
