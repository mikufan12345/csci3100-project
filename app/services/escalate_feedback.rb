# Business Rule 3: three distinct playtesters reporting the same RuleModule
# at the same severity create one escalation for that module and severity and
# raise the priority of the reports that can still be touched.
#
#   - The same playtester counting three times never escalates.
#   - A fourth (or later) distinct playtester joins the existing escalation.
#   - Feedback on an archived version counts toward the three distinct
#     playtesters, but that row is never updated.
#
# Called from Feedback's after_create, inside the feedback's own
# transaction, so a rolled-back save rolls the escalation back with it.
class EscalateFeedback
  DISTINCT_PLAYTESTERS = 3

  def self.call(feedback)
    new(feedback).call
  end

  def initialize(feedback)
    @feedback = feedback
  end

  def call
    peers = Feedback.where(rule_module: @feedback.rule_module, severity: @feedback.severity)
    distinct_playtesters =
      peers.joins(:playtest_session).distinct.count(PlaytestSession.arel_table[:user_id])
    return if distinct_playtesters < DISTINCT_PLAYTESTERS

    escalation = Escalation.find_or_create_by!(
      rule_module: @feedback.rule_module,
      severity: @feedback.severity
    ) { |row| row.priority = Escalation::PRIORITY_ESCALATED }

    # Rows on an archived version count above but are history: never written.
    live = peers
           .joins(playtest_session: :rulebook_version)
           .where(rulebook_versions: { status: RulebookVersion::STATUS_PUBLIC })
    live.find_each do |row|
      row.update_columns(
        priority: Escalation::PRIORITY_ESCALATED,
        escalation_id: escalation.id
      )
    end
  end
end