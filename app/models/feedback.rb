class Feedback < ApplicationRecord
  # Feedback status (feedbacks.status, integer)
  STATUS_UNREVIEWED         = 0
  STATUS_VALID_BUG          = 1
  STATUS_WORKING_AS_INTENDED = 2
  STATUS_RE_EVALUATION      = 3

  STATUSES = {
    "unreviewed" => STATUS_UNREVIEWED,
    "valid_bug" => STATUS_VALID_BUG,
    "working_as_intended" => STATUS_WORKING_AS_INTENDED,
    "re_evaluation" => STATUS_RE_EVALUATION
  }.freeze

  # Severity (feedbacks.severity, integer)
  SEVERITY_LOW    = 0
  SEVERITY_MEDIUM = 1
  SEVERITY_HIGH   = 2

  SEVERITIES = { "low" => SEVERITY_LOW, "medium" => SEVERITY_MEDIUM, "high" => SEVERITY_HIGH }.freeze

  # The only verdicts a rules arbiter (or admin) may post on triage.
  TRIAGE_VERDICTS = %w[valid_bug working_as_intended].freeze

  # Priority (feedbacks.priority and escalations.priority, integer)
  PRIORITY_NORMAL    = 0
  PRIORITY_ESCALATED = 1

  PRIORITIES = { "normal" => PRIORITY_NORMAL, "escalated" => PRIORITY_ESCALATED }.freeze

  belongs_to :playtest_session
  belongs_to :rule_module
  belongs_to :escalation, optional: true

  # Omitted severity is low. An explicit nil still fails inclusion, which is
  # what "requires a severity" asserts.
  attribute :severity, :integer, default: 0

  validates :comments, presence: true
  validates :severity, inclusion: { in: [0, 1, 2] }

  before_validation :assign_unreviewed_status, on: :create
  before_validation :clear_posted_priority, on: :create
  after_create :record_priority_escalation
  validate :session_meets_play_gate
  validate :module_included_in_version
  validate :freeze_comments, on: :update
  validate :freeze_archived_version, on: :update

  def status_name
    self.class::STATUSES.key(status)
  end

  def severity_name
    self.class::SEVERITIES.key(severity)
  end

  # BR4: feedback on an archived version is read-only for everyone.
  # The BR2 re-evaluation stamp runs while the older version is still
  # public, so it is never blocked by this check.
  def archived?
    version = playtest_session&.rulebook_version
    return false if version.nil?

    # reload: a fixture or a concurrent publish may have moved the version
    # past the status cached on the in-memory association.
    version.reload.status == RulebookVersion::STATUS_ARCHIVED
  end

  private

  def assign_unreviewed_status
    self.status = 0 if status.nil?
  end

  # Priority is not something a player can ask for: a posted value is
  # dropped and only EscalateFeedback may raise it, and only on a row that
  # survives past create.
  def clear_posted_priority
    self.priority = Escalation::PRIORITY_NORMAL
  end

  # Business Rule 3 runs inside the same transaction as the save.
  def record_priority_escalation
    EscalateFeedback.call(self)
  end

  def module_included_in_version
    version = playtest_session&.rulebook_version
    return if version.nil? || rule_module.nil?
    return if version.rule_modules.exists?(id: rule_module.id)

    errors.add(:rule_module, "is not in this rulebook version")
  end

  # Submitted comments stay byte-for-byte. A later save may still change
  # other columns; this slice does not decide which of those writes succeed.
  def freeze_comments
    return unless will_save_change_to_comments?

    errors.add(:comments, "cannot change after submission")
  end

  # BR4: once the session's version is archived, no column of the row may
  # change, for any role.
  def freeze_archived_version
    return unless archived?
    return unless any_will_change?

    errors.add(:status, "is frozen while its rulebook version is archived")
  end

  def any_will_change?
    %i[comments status severity priority rule_module_id playtest_session_id escalation_id]
      .any? { |column| send("will_save_change_to_#{column}?") }
  end

  # BR1: the session itself may be short. Feedback may not.
  def session_meets_play_gate
    played = playtest_session
    return if played.nil?

    if played.playtime_minutes.to_i < 30
      errors.add(:base, "Playtime must be at least 30 minutes.")
    end
    if played.scenarios_completed.to_i < 2
      errors.add(:base, "At least 2 scenarios must be completed.")
    end
  end
end
