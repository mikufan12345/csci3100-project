# frozen_string_literal: true

# Builds the rows the unit examples need from the current schema.
# Examples that assign summary, severity, priority, or Escalation are expected
# to fail until those columns and that model exist. Do not rescue those errors.
module PlaytestFixtures
  def studio!(name = "Neon Dice Co.")
    Studio.create!(name: name)
  end

  def member!(studio, role, email)
    User.create!(email: email, password: "password123", studio: studio, role: role)
  end

  def game!(studio, title = "Gloomhaven Remix")
    GameProject.create!(studio: studio, title: title)
  end

  def mod!(game, title)
    RuleModule.create!(game_project: game, title: title, deprecated: 0)
  end

  def version!(game, number:, status:)
    RulebookVersion.create!(
      game_project: game,
      version_number: number,
      status: status,
      summary: "Current rules."
    )
  end

  def session!(user, version, minutes: 45, scenarios: 2)
    PlaytestSession.create!(
      user: user,
      rulebook_version: version,
      playtime_minutes: minutes,
      scenarios_completed: scenarios
    )
  end

  def feedback!(session, rule_module, comments:, status: 0, severity: nil, priority: nil)
    attributes = {
      playtest_session: session,
      rule_module: rule_module,
      comments: comments,
      status: status
    }
    attributes[:severity] = severity unless severity.nil?
    attributes[:priority] = priority unless priority.nil?
    Feedback.create!(attributes)
  end
end
