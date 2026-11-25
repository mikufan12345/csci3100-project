# frozen_string_literal: true

require "rails_helper"

RSpec.describe Feedback, type: :model do
  let(:studio) { studio!("Neon Dice Co.") }
  let(:playtester) { member!(studio, User::PLAYTESTER, "carol@example.com") }
  let(:game) { game!(studio) }
  let(:rule_module) { mod!(game, "Combat") }
  let(:other_module) { mod!(game, "Magic") }
  let(:version) { version!(game, number: 1, status: 1) }
  let(:qualified) { session!(playtester, version, minutes: 30, scenarios: 2) }

  def build_feedback(session, comments, **attrs)
    Feedback.new({
      playtest_session: session,
      rule_module: rule_module,
      comments: comments,
      status: 0
    }.merge(attrs))
  end

  it "stores feedback at 30 minutes and 2 scenarios" do
    feedback = build_feedback(qualified, "Long enough to count.")
    expect(feedback).to be_valid
    expect { feedback.save! }.to change(Feedback, :count).by(1)
    expect(feedback.reload.comments).to eq("Long enough to count.")
    expect(feedback.status).to eq(0)
  end

  it "rejects feedback under 30 minutes and stores nothing" do
    short = session!(playtester, version, minutes: 29, scenarios: 2)
    feedback = build_feedback(short, "Too short to count.")
    expect(feedback).not_to be_valid
    expect(feedback.errors.full_messages).to include("Playtime must be at least 30 minutes.")
    expect { feedback.save }.not_to change(Feedback, :count)
  end

  it "rejects feedback with fewer than 2 scenarios and stores nothing" do
    thin = session!(playtester, version, minutes: 30, scenarios: 1)
    feedback = build_feedback(thin, "Too few scenarios.")
    expect(feedback).not_to be_valid
    expect(feedback.errors.full_messages).to include("At least 2 scenarios must be completed.")
    expect { feedback.save }.not_to change(Feedback, :count)
  end

  it "requires comments" do
    feedback = build_feedback(qualified, "")
    expect(feedback).not_to be_valid
  end

  it "requires a severity" do
    feedback = build_feedback(qualified, "Missing severity.", severity: nil)
    expect(feedback).not_to be_valid
  end

  it "rejects a module that is not in the session's version" do
    feedback = build_feedback(qualified, "Magic was not in this book.", rule_module: other_module)
    expect(feedback).not_to be_valid
  end

  it "keeps the submitted comments when a later save posts new text" do
    feedback = build_feedback(qualified, "Keep this sentence.")
    feedback.save!
    feedback.comments = "Tampered sentence."
    feedback.status = 1
    feedback.save
    reloaded = Feedback.find(feedback.id)
    expect(reloaded.comments).to eq("Keep this sentence.")
  end

  it "refuses a status change once the version is archived" do
    feedback = build_feedback(qualified, "Keep this sentence.")
    feedback.save!
    version.update_columns(status: 2)
    feedback.status = 1
    feedback.save
    expect(feedback.reload.status).to eq(0)
  end

  it "does not let a caller set escalated priority on a lone report" do
    feedback = build_feedback(qualified, "Please escalate me.", priority: 1)
    feedback.save!
    expect(feedback.reload.priority).to eq(0)
    expect(Escalation.count).to eq(0)
  end
end
