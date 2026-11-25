class PlaytestSessionsController < ApplicationController
  before_action :authenticate_user!

  def create
    version = version_in_studio
    return if performed?

    @session = current_user.playtest_sessions.new(session_params)
    @session.rulebook_version = version

    if @session.save
      redirect_to game_project_path(version.game_project)
    else
      @game_project = version.game_project
      @public_version = version
      @feedback = nil
      render "game_projects/show", status: :unprocessable_entity
    end
  end

  def update
    @session = owned_session
    @session.update(session_params)
    redirect_to game_project_path(@session.rulebook_version.game_project)
  end

  private

  def version_in_studio
    RulebookVersion.joins(:game_project).merge(@studio.game_projects).find(params[:rulebook_version_id])
  rescue ActiveRecord::RecordNotFound
    render plain: "not found", status: :not_found
    nil
  end

  def owned_session
    current_user.playtest_sessions.joins(rulebook_version: :game_project).merge(@studio.game_projects).find(params[:id])
  end

  def session_params
    params.require(:playtest_session).permit(:playtime_minutes, :scenarios_completed)
  end
end
