# Enforces multi-tenancy for every controller that includes it (i.e. all of
# them, via ApplicationController). Two jobs:
#
#   1. Whose data?  Resolves @studio from the signed-in user. Data reads go
#      through find_in_studio, and data writes through @studio.<association>,
#      so records outside the studio are indistinguishable from nonexistent
#      ones (a 404 is returned if you are not supposed to see the game).
#   2. May you act? authorize_role! rejects actions the user's role is not
#      permitted to perform (403).
#
# Do NOT query global tables in controllers.
module StudioIsolationEnforcer
  extend ActiveSupport::Concern

  included do
    before_action :require_studio
  end

  private

  # Runs before every action. @studio stays nil if not signed in; the helpers
  # below refuse to do anything in that case. Redirecting guests to the
  # sign-in page is Devise's job: each controller that protects data registers
  # `before_action :authenticate_user!` (see GameProjectsController).
  def require_studio
    @studio = current_user&.studio
  end

  # Find a record inside the current studio's fence, or 404.
  #   find_in_studio(GameProject, params[:id])
  # Works for any table carrying studio_id (game_projects, users, ...).
  def find_in_studio(model, id)
    raise "not in a studio context" if @studio.nil?
    model.where(studio_id: @studio.id).find(id)
  # The rescue makes the 404 explicit so it holds in every environment
  # (the test environment rethrows unhandled exceptions instead of 404-ing).
  rescue ActiveRecord::RecordNotFound
    render plain: "not found", status: :not_found
    nil
  end

  # Role gate. Usage:
  #   authorize_role!(User::STUDIO_ADMIN)
  #   authorize_role!(User::STUDIO_ADMIN, User::ARBITER)
  # Returns true when the action may proceed; renders a 403 and returns nil
  # otherwise (the caller then halts the action).
  def authorize_role!(*allowed_roles)
    if current_user && allowed_roles.include?(current_user.role)
      true
    else
      render plain: "forbidden", status: :forbidden
      nil
    end
  end
end