# frozen_string_literal: true

require "rails_helper"

RSpec.describe "game project permissions", type: :request do
  let(:neon) { studio!("Neon Dice Co.") }
  let(:dragon) { studio!("Dragon's Lair Designs") }
  let(:alice) { member!(neon, User::STUDIO_ADMIN, "alice@example.com") }
  let(:carol) { member!(neon, User::PLAYTESTER, "carol@example.com") }
  let(:foreign_game) { game!(dragon, "Lorebreakers") }

  it "returns 404 when an admin opens another studio's game" do
    sign_in alice
    get game_project_path(foreign_game)
    expect(response).to have_http_status(:not_found)
  end

  it "returns 403 when a playtester creates a game" do
    sign_in carol
    post game_projects_path, params: { game_project: { title: "Sneaky" } }
    expect(response).to have_http_status(:forbidden)
    expect(neon.game_projects.where(title: "Sneaky")).to be_empty
  end

  it "rejects a blank title" do
    sign_in alice
    post game_projects_path, params: { game_project: { title: "" } }
    expect(response).to have_http_status(:unprocessable_entity)
    expect(neon.game_projects).to be_empty
  end
end
