# An escalation groups three or more playtesters who reported the same
# RuleModule at the same severity (Business Rule 3). One row per
# module + severity; later reporters join the existing row.
class Escalation < ApplicationRecord
  # Priority (escalations.priority and feedbacks.priority, integer)
  PRIORITY_NORMAL    = 0
  PRIORITY_ESCALATED = 1

  belongs_to :rule_module
  has_many :feedbacks, dependent: :nullify

  validates :severity, inclusion: { in: Feedback::SEVERITIES.values }

  def severity_name
    Feedback::SEVERITIES.key(severity)
  end
end