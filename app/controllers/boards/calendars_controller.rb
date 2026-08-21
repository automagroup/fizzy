class Boards::CalendarsController < ApplicationController
  include BoardScoped

  def show
    @month = requested_month

    unless @month
      redirect_to board_calendar_path(@board, month: Date.current.strftime("%Y-%m"))
      return
    end

    @calendar_start = @month.beginning_of_week(:monday)
    @calendar_end = @month.end_of_month.end_of_week(:monday)
    @weeks = (@calendar_start..@calendar_end).each_slice(7).to_a

    due_on = @month..@month.end_of_month
    @projects_by_date = @board.projects.where(due_on: due_on).chronologically.group_by(&:due_on)
    @milestones_by_date = @board.milestones.where(due_on: due_on).includes(project: :board).chronologically.group_by(&:due_on)
  end

  private
    def requested_month
      if params[:month].blank?
        Date.current.beginning_of_month
      elsif params[:month].match?(/\A\d{4}-\d{2}\z/)
        Date.strptime(params[:month], "%Y-%m").beginning_of_month
      end
    rescue Date::Error
    end
end
