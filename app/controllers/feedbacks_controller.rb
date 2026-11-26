class FeedbacksController < ApplicationController
  before_action :authenticate_user!

  def create
    @session = current_user.playtest_sessions.joins(rulebook_version: :game_project).merge(@studio.game_projects).find(params[:playtest_session_id])
    @feedback = @session.feedbacks.new(feedback_params)

    if @feedback.save
      redirect_to game_project_path(@session.rulebook_version.game_project)
    else
      @game_project = @session.rulebook_version.game_project
      @public_version = @game_project.rulebook_versions.find_by(status: 1)
      render "game_projects/show", status: :unprocessable_entity
    end
  rescue ActiveRecord::RecordNotFound
    render plain: "not found", status: :not_found
  end

  # Story 3: the triage list. Arbiters and admins see the studio's feedback;
  # a playtester gets a 403. Optional filters: ?status= (defaults to
  # unreviewed, "all" lifts the status filter), ?severity=, ?priority=,
  # and ?game_project_id= — all using the word names from Feedback's maps.
  def index
    return unless authorize_role!(User::STUDIO_ADMIN, User::ARBITER)

    @feedbacks = studio_feedback
                 .includes(:rule_module, playtest_session: { rulebook_version: :game_project })
    status = params[:status].presence || "unreviewed"
    if status != "all"
      value = Feedback::STATUSES.fetch(status, nil)
      return render plain: "unknown status", status: :unprocessable_entity if value.nil?

      @feedbacks = @feedbacks.where(status: value)
    end
    if params[:severity].present?
      severity = Feedback::SEVERITIES.fetch(params[:severity], nil)
      return render plain: "unknown severity", status: :unprocessable_entity if severity.nil?

      @feedbacks = @feedbacks.where(severity: severity)
    end
    if params[:priority].present?
      priority = Feedback::PRIORITIES.fetch(params[:priority], nil)
      return render plain: "unknown priority", status: :unprocessable_entity if priority.nil?

      @feedbacks = @feedbacks.where(priority: priority)
    end
    if params[:game_project_id].present?
      @feedbacks = @feedbacks.where(rulebook_versions: { game_project_id: params[:game_project_id] })
    end
    @feedbacks = @feedbacks.order(created_at: :desc, id: :desc)
  end

  # Arbiters and admins may read any row in the studio; a playtester may
  # read only their own (another playtester's row is a 404). Another
  # studio's id is a 404 for everyone.
  def show
    @feedback = studio_feedback.find(params[:id])
    if current_user.role == User::PLAYTESTER && @feedback.playtest_session.user_id != current_user.id
      return render plain: "not found", status: :not_found
    end
  rescue ActiveRecord::RecordNotFound
    render plain: "not found", status: :not_found
  end

  # Triage is a status-only write. Comments, severity, and priority are not
  # permitted here: the playtester's sentence is byte-for-byte immutable and
  # only the escalation service may set priority. BR4: once the version is
  # archived, even an admin gets a 403.
  def update
    return unless authorize_role!(User::STUDIO_ADMIN, User::ARBITER)

    @feedback = studio_feedback.find(params[:id])
    return if @feedback.nil?

    if @feedback.archived?
      render plain: "Archived feedback is read-only.", status: :forbidden
      return
    end

    posted = params.dig(:feedback, :status).to_s
    if Feedback::TRIAGE_VERDICTS.exclude?(posted)
      render plain: "The verdict must be valid_bug or working_as_intended.", status: :unprocessable_entity
      return
    end

    if @feedback.update(status: Feedback::STATUSES.fetch(posted))
      redirect_to game_project_path(@feedback.playtest_session.rulebook_version.game_project)
    else
      render plain: @feedback.errors.full_messages.join("\n"), status: :unprocessable_entity
    end
  rescue ActiveRecord::RecordNotFound
    render plain: "not found", status: :not_found
  end

  private

  # Every feedback row reachable from the studio's games.
  def studio_feedback
    Feedback.joins(playtest_session: { rulebook_version: :game_project })
            .merge(@studio.game_projects)
  end

  def feedback_params
    params.require(:feedback).permit(:rule_module_id, :severity, :comments)
  end
end