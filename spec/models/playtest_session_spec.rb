# frozen_string_literal: true

require "rails_helper"

RSpec.describe PlaytestSession, type: :model do
  let(:studio) { studio!("Neon Dice Co.") }
  let(:other) { studio!("Dragon's Lair Designs") }
  let(:playtester) { member!(studio, User::PLAYTESTER, "carol@example.com") }
  let(:game) { game!(studio) }
  let(:public_version) { version!(game, number: 1, status: 1) }

  it "saves a session below the feedback gate" do
    session = session!(playtester, public_version, minutes: 10, scenarios: 0)
    expect(session).to be_persisted
  end

  it "rejects a session on a draft version" do
    draft = version!(game, number: 2, status: 0)
    session = PlaytestSession.new(user: playtester, rulebook_version: draft, playtime_minutes: 40, scenarios_completed: 2)
    expect(session).not_to be_valid
  end

  it "rejects a session on an archived version" do
    archived = version!(game, number: 2, status: 2)
    session = PlaytestSession.new(user: playtester, rulebook_version: archived, playtime_minutes: 40, scenarios_completed: 2)
    expect(session).not_to be_valid
  end

  it "rejects a session whose version belongs to another studio" do
    foreign = version!(game!(other, "Lorebreakers"), number: 1, status: 1)
    session = PlaytestSession.new(user: playtester, rulebook_version: foreign, playtime_minutes: 40, scenarios_completed: 2)
    expect(session).not_to be_valid
  end

  it "freezes playtime and scenario count after feedback exists" do
    rule_module = mod!(game, "Combat")
    played = session!(playtester, public_version, minutes: 45, scenarios: 3)
    feedback!(played, rule_module, comments: "Long enough to count.")
    played.playtime_minutes = 5
    played.scenarios_completed = 0
    played.save
    played.reload
    expect(played.playtime_minutes).to eq(45)
    expect(played.scenarios_completed).to eq(3)
  end

  it "rejects a negative playtime" do
    session = PlaytestSession.new(user: playtester, rulebook_version: public_version, playtime_minutes: -10, scenarios_completed: 2)
    expect(session).not_to be_valid
  end

  it "rejects a negative scenario count" do
    session = PlaytestSession.new(user: playtester, rulebook_version: public_version, playtime_minutes: 40, scenarios_completed: -1)
    expect(session).not_to be_valid
  end

  it "requires both numbers to be present" do
    session = PlaytestSession.new(user: playtester, rulebook_version: public_version, playtime_minutes: nil, scenarios_completed: nil)
    expect(session).not_to be_valid
  end
end
