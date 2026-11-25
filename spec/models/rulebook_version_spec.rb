# frozen_string_literal: true

require "rails_helper"

RSpec.describe RulebookVersion, type: :model do
  let(:studio) { studio!("Neon Dice Co.") }
  let(:game) { game!(studio) }

  it "allows a draft beside the public version" do
    version!(game, number: 1, status: 1)
    draft = version!(game, number: 2, status: 0)
    expect(draft).to be_persisted
    expect(game.rulebook_versions.where(status: 1).count).to eq(1)
  end

  it "rejects a second public version of the same game" do
    version!(game, number: 1, status: 1)
    second = RulebookVersion.new(game_project: game, version_number: 2, status: 1)
    expect(second).not_to be_valid
  end

  it "requires a summary before publish" do
    version = RulebookVersion.new(game_project: game, version_number: 1, status: 1, summary: "")
    expect(version).not_to be_valid
    expect(version.errors[:summary]).not_to be_empty
  end

  it "does not change a summary after the version leaves draft" do
    version = RulebookVersion.create!(
      game_project: game,
      version_number: 1,
      status: 1,
      summary: "The first public rules."
    )
    version.summary = "Secretly rewritten."
    version.save
    expect(version.reload.summary).to eq("The first public rules.")
  end
end
