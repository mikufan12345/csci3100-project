# frozen_string_literal: true

require "rails_helper"

RSpec.describe GameProject, type: :model do
  it "requires a title" do
    studio = studio!("Neon Dice Co.")
    game = GameProject.new(studio: studio, title: "  ")
    expect(game).not_to be_valid
  end

  it "belongs to the studio that created it" do
    studio = studio!("Neon Dice Co.")
    game = GameProject.create!(studio: studio, title: "Gloomhaven Remix")
    expect(game.studio).to eq(studio)
  end
end
