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
        render :new, status: :unprocessable_entity
      end
    end
  end

  private

  def game_params
    params.require(:game_project).permit(:title)
  end
end