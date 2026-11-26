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
      @public_version = @game_project.rulebook_versions.find_by(status: 1)
      @feedback = nil
      render "game_projects/show", status: :unprocessable_entity
    end
  end

  # The session's owner keeps their row while the rulebook is public; an
  # admin may correct any row in the studio. BR4 blocks both once the
  # version is archived (model validation).
  def update
    @session = session_in_studio
    return if @session.nil?

    unless current_user.role == User::STUDIO_ADMIN || @session.user_id == current_user.id
      render plain: "forbidden", status: :forbidden
      return
    end

    if @session.update(session_params)
      redirect_to game_project_path(@session.rulebook_version.game_project)
    else
      render plain: @session.errors.full_messages.join("\n"), status: :unprocessable_entity
    end
  end

  private

  def version_in_studio
    RulebookVersion.joins(:game_project).merge(@studio.game_projects).find(params[:rulebook_version_id])
  rescue ActiveRecord::RecordNotFound
    render plain: "not found", status: :not_found
    nil
  end

  def session_in_studio
    PlaytestSession.joins(rulebook_version: :game_project).merge(@studio.game_projects).find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render plain: "not found", status: :not_found
    nil
  end

  def session_params
    params.require(:playtest_session).permit(:playtime_minutes, :scenarios_completed)
  end
end
