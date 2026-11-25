class GameProjectsController < ApplicationController
  # StudioIsolationEnforcer comes in via ApplicationController:
  # @studio is already resolved before each action.
  # Guests are redirected to the sign-in page for every page but the public index.
  before_action :authenticate_user!, except: [:index]

  def index
    @game_projects = @studio ? @studio.game_projects.order(:title) : GameProject.none
  end

  def show
    # Outside a studio -> RecordNotFound -> 404, as if the game doesn't exist
    @game_project = find_in_studio(GameProject, params[:id])
    return if @game_project.nil?

    @public_version = @game_project.rulebook_versions.find_by(status: 1)
    if @public_version
      @session = current_user.playtest_sessions.where(rulebook_version: @public_version).order(:id).last
      @feedback = @session.feedbacks.build if @session
    end
  end

  def new
    if authorize_role!(User::STUDIO_ADMIN)
      @game_project = @studio.game_projects.build
    end
  end

  def create
    if authorize_role!(User::STUDIO_ADMIN)
      @game_project = @studio.game_projects.new(game_params)

      if @game_project.save
        redirect_to @game_project, notice: "Game created."
      else
        # The failed build stays on the in-memory association. Drop it so a
        # later read of this studio matches the database.
        @studio.game_projects.reset
        render :new, status: :unprocessable_entity
      end
    end
  end

  private

  def game_params
    params.require(:game_project).permit(:title)
  end
end