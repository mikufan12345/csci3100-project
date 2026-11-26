# Synthetic demo data for the course (docs/refined_proposal.md, section 8).
#
# Idempotent: every record is found-or-created, so the file can run at any
# point in any environment. It creates the two demo studios with their six
# accounts (the same table is printed in the README), one game, two modules,
# and one public version per studio. It creates no feedback: demo feedback
# is created through the UI so the video shows the real rules.

DEMO_PASSWORD = "PlaytestDemo!2026"

DEMO_STUDIOS = {
  "Neon Dice Co." => {
    game: "Gloomhaven Remix",
    modules: ["Combat", "Magic"],
    summary: "Neon Dice Co.'s current public rules."
  },
  "Dragon's Lair Designs" => {
    game: "Lorebreakers",
    modules: ["Heist", "Siege"],
    summary: "Dragon's Lair Designs' current public rules."
  }
}.freeze

DEMO_ACCOUNTS = [
  { email: "neon-admin@example.com",     studio: "Neon Dice Co.",          role: User::STUDIO_ADMIN },
  { email: "neon-play@example.com",      studio: "Neon Dice Co.",          role: User::PLAYTESTER },
  { email: "neon-arbiter@example.com",   studio: "Neon Dice Co.",          role: User::ARBITER },
  { email: "dragon-admin@example.com",   studio: "Dragon's Lair Designs",  role: User::STUDIO_ADMIN },
  { email: "dragon-play@example.com",    studio: "Dragon's Lair Designs",  role: User::PLAYTESTER },
  { email: "dragon-arbiter@example.com", studio: "Dragon's Lair Designs",  role: User::ARBITER }
].freeze

DEMO_STUDIOS.each do |studio_name, game_seed|
  studio = Studio.find_or_create_by!(name: studio_name)

  DEMO_ACCOUNTS.select { |account| account[:studio] == studio_name }.each do |account|
    user = User.find_by(email: account[:email])
    if user.nil?
      user = User.new(email: account[:email],
                      password: DEMO_PASSWORD,
                      password_confirmation: DEMO_PASSWORD)
    end
    # Bypass the signup rule: seeds are an operator action, not a sign-up.
    user.studio = studio
    user.role = account[:role]
    user.save!
  end

  game = studio.game_projects.find_or_create_by!(title: game_seed[:game])
  game_seed[:modules].each do |title|
    game.rule_modules.find_or_create_by!(title: title)
  end

  version = game.rulebook_versions.find_by(version_number: 1)
  version ||= game.rulebook_versions.create!(version_number: 1,
                                             status: RulebookVersion::STATUS_DRAFT,
                                             summary: game_seed[:summary])
  version.update!(status: RulebookVersion::STATUS_PUBLIC) if version.status != RulebookVersion::STATUS_PUBLIC

  game.rule_modules.find_each do |rule_module|
    RulebookInclusion.find_or_create_by!(rulebook_version: version, rule_module: rule_module)
  end
end