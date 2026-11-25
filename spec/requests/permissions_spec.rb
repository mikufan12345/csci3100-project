# frozen_string_literal: true

require "rails_helper"

RSpec.describe "direct requests for rules and feedback", type: :request do
  let(:neon) { studio!("Neon Dice Co.") }
  let(:dragon) { studio!("Dragon's Lair Designs") }
  let(:alice) { member!(neon, User::STUDIO_ADMIN, "alice@example.com") }
  let(:carol) { member!(neon, User::PLAYTESTER, "carol@example.com") }
  let(:dave) { member!(neon, User::ARBITER, "dave@example.com") }
  let(:erin) { member!(dragon, User::PLAYTESTER, "erin@example.com") }
  let(:game) { game!(neon) }
  let(:combat) { mod!(game, "Combat") }
  let(:current) { version!(game, number: 1, status: 1) }
  let(:draft) { version!(game, number: 2, status: 0) }
  let(:note) do
    feedback!(session!(carol, current), combat, comments: "The combat round runs too long.")
  end

  it "returns 403 when a playtester publishes" do
    sign_in carol
    post "/rulebook_versions/#{draft.id}/publish"
    expect(response).to have_http_status(:forbidden)
    expect(draft.reload.status).to eq(0)
  end

  it "returns 403 when an arbiter publishes" do
    sign_in dave
    post "/rulebook_versions/#{draft.id}/publish"
    expect(response).to have_http_status(:forbidden)
  end

  it "returns 404 when another studio opens a version" do
    sign_in erin
    get "/rulebook_versions/#{current.id}"
    expect(response).to have_http_status(:not_found)
  end

  it "returns 403 when a playtester opens the triage list" do
    sign_in carol
    get "/feedbacks"
    expect(response).to have_http_status(:forbidden)
  end

  it "returns 404 when an arbiter opens another studio's feedback" do
    foreign_game = game!(dragon, "Lorebreakers")
    foreign_module = mod!(foreign_game, "Heist")
    foreign_version = version!(foreign_game, number: 1, status: 1)
    foreign = feedback!(
      session!(erin, foreign_version),
      foreign_module,
      comments: "The heist timer is fine."
    )
    sign_in dave
    get "/feedbacks/#{foreign.id}"
    expect(response).to have_http_status(:not_found)
  end

  it "keeps comments when an arbiter posts a new sentence with a verdict" do
    sign_in dave
    patch "/feedbacks/#{note.id}", params: {
      feedback: { comments: "Tampered sentence.", status: "valid_bug", severity: "low", priority: "escalated" }
    }
    reloaded = note.reload
    expect(reloaded.comments).to eq("The combat round runs too long.")
    expect(reloaded.status).to eq(1)
  end

  it "returns 404 when an admin edits a member of another studio" do
    sign_in alice
    patch "/studio_members/#{erin.id}", params: { user: { role: "playtester" } }
    expect(response).to have_http_status(:not_found)
    expect(erin.reload.role).to eq(User::PLAYTESTER)
  end
end
