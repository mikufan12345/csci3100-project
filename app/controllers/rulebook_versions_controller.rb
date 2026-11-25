class RulebookVersionsController < ApplicationController
  before_action :authenticate_user!

  def show
    @version = version_in_studio
    return if @version.nil?
  end

  def create
    game = find_in_studio(GameProject, params[:game_project_id])
    return if game.nil?
    return unless authorize_role!(User::STUDIO_ADMIN)

    version = game.rulebook_versions.new(
      status: 0,
      summary: params.dig(:rulebook_version, :summary).to_s,
      version_number: (game.rulebook_versions.maximum(:version_number) || 0) + 1
    )

    RulebookVersion.transaction do
      version.save!
      game.rule_modules.where(id: Array(params[:module_ids])).find_each do |rule_module|
        version.rulebook_inclusions.create!(rule_module: rule_module)
      end
    end

    redirect_to game_project_path(game)
  rescue ActiveRecord::RecordInvalid
    @game_project = game
    @public_version = game.rulebook_versions.find_by(status: 1)
    render "game_projects/show", status: :unprocessable_entity
  end

  def update
    @version = version_in_studio
    return if @version.nil?
    return unless authorize_role!(User::STUDIO_ADMIN)

    if @version.update(version_params)
      redirect_to game_project_path(@version.game_project)
    else
      render plain: @version.errors.full_messages.join("\n"), status: :unprocessable_entity
    end
  end

  def publish
    @version = version_in_studio
    return if @version.nil?
    return unless authorize_role!(User::STUDIO_ADMIN)

    published = PublishRulebookVersion.new(
      version: @version,
      deprecate_module_ids: Array(params[:deprecate_ids]),
      replacements: replacement_params
    ).call

    if published
      redirect_to game_project_path(@version.game_project)
    else
      render plain: @version.errors.full_messages.presence&.join("\n") || "cannot publish",
             status: :unprocessable_entity
    end
  end

  private

  def version_in_studio
    RulebookVersion.joins(:game_project).merge(@studio.game_projects).find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render plain: "not found", status: :not_found
    nil
  end

  def version_params
    params.require(:rulebook_version).permit(:summary)
  end

  def replacement_params
    raw = params[:replacements]
    return {} if raw.nil?
    return raw.to_unsafe_h if raw.respond_to?(:to_unsafe_h)

    raw
  end
end
