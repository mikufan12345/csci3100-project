class ApplicationController < ActionController::Base
  # Every controller in the app is fenced to the signed-in user's studio.
  # There is no opt-out: anything that inherits ApplicationController (which
  # is everything, including Devise's controllers) gets require_studio before
  # each action.
  include StudioIsolationEnforcer

  before_action :configure_permitted_parameters, if: :devise_controller?

  private

  # Signup may send a studio name. It may not send a role: the model assigns
  # admin to the founder and playtester to everyone who joins later.
  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: [:studio_name])
  end
end