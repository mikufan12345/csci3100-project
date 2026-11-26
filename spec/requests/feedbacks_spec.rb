# frozen_string_literal

require "rails_helper"

RSpec.describe "feedback list and visibility", type: :request do
  let(:neon) { studio!("Neon Dice Co.") }
  let(:dragon) { studio!("Dragon's Lair Designs") }
  let(:alice) { member!(neon, User::STUDIO_ADMIN, "alice@example.com") }
  let(:carol) { member!(neon, User::PLAYTESTER, "carol@example.com") }
  let(:frank) { member!(neon, User::PLAYTESTER, "frank@example.com") }
  let(:dave) { member!(neon, User::ARBITER, "dave@example.com") }
  let(:erin) { member!(dragon, User::PLAYTESTER, "erin@example.com") }
  let(:game) { game!(neon) }
  let(:combat) { mod!(game, "Combat") }
  let(:current) { version!(game, number: 1, status: 1) }
  let(:carol_note) { feedback!(session!(carol, current), combat, comments: "Carol sees the deck.") }
  let(:carol_bug) do
    feedback!(session!(carol, current), combat, comments: "Carol found a bug.", status: 1)
  end
  let(:frank_note) { feedback!(session!(frank, current), combat, comments: "Frank keeps the coin.") }

  it "defaults the triage list to the studio's unreviewed feedback" do
    carol_note
    carol_bug
    sign_in dave
    get "/feedbacks"
    expect(response.body).to include("Carol sees the deck.")
    expect(response.body).not_to include("Carol found a bug.")
  end

  it "lists every status when asked for all" do
    carol_note
    carol_bug
    sign_in dave
    get "/feedbacks?status=all"
    expect(response.body).to include("Carol found a bug.")
    expect(response.body).to include("Carol sees the deck.")
  end

  it "rejects an unknown status" do
    sign_in dave
    get "/feedbacks?status=settled"
    expect(response).to have_http_status(:unprocessable_entity)
  end

  it "lets a playtester read their own row" do
    sign_in carol
    get "/feedbacks/#{carol_note.id}"
    expect(response).to have_http_status(:ok)
  end

  it "returns 404 when a playtester reads another playtester's row" do
    sign_in carol
    get "/feedbacks/#{frank_note.id}"
    expect(response).to have_http_status(:not_found)
  end

  it "returns 404 when a playtester gives feedback on a foreign studio's session" do
    foreign_game = game!(dragon, "Lorebreakers")
    foreign_version = version!(foreign_game, number: 1, status: 1)
    foreign_session = session!(erin, foreign_version, minutes: 40, scenarios: 2)
    sign_in carol
    post "/feedbacks", params: {
      playtest_session_id: foreign_session.id,
      feedback: { rule_module_id: combat.id, severity: "low", comments: "Not my session." }
    }
    expect(response).to have_http_status(:not_found)
    expect(Feedback.where(comments: "Not my session.").count).to be_zero
  end
end