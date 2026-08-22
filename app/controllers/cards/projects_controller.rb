class Cards::ProjectsController < ApplicationController
  include CardScoped

  def edit
    @projects = @board.projects.chronologically.includes(:milestones).load
    render :picker if turbo_frame_request?
  end

  def update
    project = find_project
    milestone = find_milestone(project)

    @card.assign_to_project project, milestone: milestone

    respond_to do |format|
      format.html { redirect_to @card, notice: "Project updated" }
      format.turbo_stream { render :update }
    end
  end

  def destroy
    @card.assign_to_project nil

    respond_to do |format|
      format.html { redirect_to @card, notice: "Project removed" }
      format.turbo_stream { render :update }
    end
  end

  private
    def find_project
      if project_params[:project_id].present?
        @board.projects.find(project_params[:project_id])
      end
    end

    def find_milestone(project)
      if project_params[:milestone_id].present?
        unless project
          raise ActiveRecord::RecordNotFound
        end

        project.milestones.find(project_params[:milestone_id])
      end
    end

    def project_params
      @project_params ||= params.expect(card: [ :project_id, :milestone_id ])
    end
end
