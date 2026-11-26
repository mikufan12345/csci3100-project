class EscalationsController < ApplicationController
  before_action :authenticate_user!

  # The escalation report is a studio-admin view of the studio's escalations.
  # Optional ?game_project_id= narrows it to one of the studio's games.
  def index
    return unless authorize_role!(User::STUDIO_ADMIN)

    @escalations = Escalation
                   .joins(rule_module: :game_project)
                   .merge(@studio.game_projects)
                   .includes(:rule_module)
    if params[:game_project_id].present?
      @escalations = @escalations.where(game_projects: { id: params[:game_project_id] })
    end
    @escalations = @escalations.order(:id)
  end
end