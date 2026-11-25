class FeedbacksController < ApplicationController
  before_action :authenticate_user!

  def create
    @session = current_user.playtest_sessions.joins(rulebook_version: :game_project).merge(@studio.game_projects).find(params[:playtest_session_id])
    @feedback = @session.feedbacks.new(feedback_params)

    if @feedback.save
      redirect_to game_project_path(@session.rulebook_version.game_project)
    else
      @game_project = @session.rulebook_version.game_project
      @public_version = @game_project.rulebook_versions.find_by(status: 1)
      render "game_projects/show", status: :unprocessable_entity
    end
  end

  private

  def feedback_params
    params.require(:feedback).permit(:rule_module_id, :severity, :comments)
  end
end
