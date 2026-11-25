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

  # Comments are not permitted. A posted sentence is applied only so the model
  # can reject it. Status, severity, and priority are left for a later slice.
  def update
    @feedback = feedback_in_studio
    return if @feedback.nil?

    posted_comments = params.dig(:feedback, :comments)
    @feedback.comments = posted_comments if params.fetch(:feedback, {}).key?(:comments)
    if @feedback.save
      redirect_to game_project_path(@feedback.playtest_session.rulebook_version.game_project)
    else
      render plain: @feedback.errors.full_messages.join("\n"), status: :unprocessable_entity
    end
  end

  private

  def feedback_in_studio
    Feedback.joins(playtest_session: { rulebook_version: :game_project })
      .merge(@studio.game_projects)
      .find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render plain: "not found", status: :not_found
    nil
  end

  def feedback_params
    params.require(:feedback).permit(:rule_module_id, :severity, :comments)
  end
end
