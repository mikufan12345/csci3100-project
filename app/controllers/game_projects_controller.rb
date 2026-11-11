class GameProjectsController < ApplicationController
  # StudioIsolationEnforcer comes in via ApplicationController:
  # @studio is already resolved before each action.

  def index
    @game_projects = @studio ? @studio.game_projects.order(:title) : GameProject.none
  end

  def show
    # Outside the fence -> RecordNotFound -> 404, as if the game doesn't exist
    @game_project = find_in_studio(GameProject, params[:id])
  end

  def new
    return unless authorize_role!(User::STUDIO_ADMIN)
    @game_project = @studio.game_projects.build
  end

  def create
    return unless authorize_role!(User::STUDIO_ADMIN)
    @game_project = @studio.game_projects.new(game_params)

    if @game_project.save
      redirect_to @game_project, notice: "Game created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  def game_params
    params.require(:game_project).permit(:title)
  end
end