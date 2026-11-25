class StudioMembersController < ApplicationController
  before_action :authenticate_user!

  # An admin may switch another member between playtester and arbiter.
  # Their own role stays put, and studio_admin cannot be granted here.
  def update
    member = find_in_studio(User, params[:id])
    return if member.nil?
    return unless authorize_role!(User::STUDIO_ADMIN)

    role = appointed_role
    if member.id == current_user.id || role.nil?
      render plain: "forbidden", status: :forbidden
      return
    end

    member.update!(role: role)
    redirect_to root_path
  end

  private

  def appointed_role
    {
      "playtester" => User::PLAYTESTER,
      "arbiter" => User::ARBITER
    }[params.dig(:user, :role).to_s]
  end
end
