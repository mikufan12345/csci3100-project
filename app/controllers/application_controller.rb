class ApplicationController < ActionController::Base
  # Every controller in the app is fenced to the signed-in user's studio.
  # There is no opt-out: anything that inherits ApplicationController (which
  # is everything, including Devise's controllers) gets require_studio before
  # each action.
  include StudioIsolationEnforcer
end