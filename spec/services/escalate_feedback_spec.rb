# frozen_string_literal: true

require "rails_helper"

# Observable rule: saving a feedback row escalates when three distinct
# playtesters share a module and a severity. The service behind that save is
# EscalateFeedback, called from feedback creation. These examples do not call
# it directly, so the behavior stays the contract.
RSpec.describe "priority escalation" do
  let(:studio) { studio!("Neon Dice Co.") }
  let(:game) { game!(studio) }
  let(:combat) { mod!(game, "Combat") }
  let(:version) { version!(game, number: 2, status: 1) }

  def report(email, comments, severity: 2, book: version)
    playtester = member!(studio, User::PLAYTESTER, email)
    feedback!(session!(playtester, book), combat, comments: comments, severity: severity)
  end

  it "does not escalate two distinct playtesters" do
    report("carol@example.com", "Carol on combat.")
    report("frank@example.com", "Frank on combat.")
    expect(Escalation.where(rule_module: combat, severity: 2).count).to eq(0)
    expect(Feedback.find_by!(comments: "Carol on combat.").priority).to eq(0)
  end

  it "does not let one playtester count three times" do
    playtester = member!(studio, User::PLAYTESTER, "carol@example.com")
    3.times do |index|
      feedback!(
        session!(playtester, version, minutes: 40 + index),
        combat,
        comments: "Carol report #{index}."
      )
    end
    expect(Escalation.count).to eq(0)
  end

  it "creates one escalation at the third distinct playtester and raises priority once" do
    report("carol@example.com", "Carol on combat.")
    report("frank@example.com", "Frank on combat.")
    report("grace@example.com", "Grace on combat.")
    escalations = Escalation.where(rule_module: combat, severity: 2)
    expect(escalations.count).to eq(1)
    expect(escalations.first.priority).to eq(1)
    ["Carol on combat.", "Frank on combat.", "Grace on combat."].each do |comments|
      expect(Feedback.find_by!(comments: comments).priority).to eq(1)
    end
  end

  it "joins a fourth playtester to the same escalation" do
    report("carol@example.com", "Carol on combat.")
    report("frank@example.com", "Frank on combat.")
    report("grace@example.com", "Grace on combat.")
    report("helen@example.com", "Helen on combat.")
    expect(Escalation.where(rule_module: combat, severity: 2).count).to eq(1)
    expect(Feedback.find_by!(comments: "Helen on combat.").priority).to eq(1)
  end

  it "does not match a different severity" do
    report("carol@example.com", "Carol high.", severity: 2)
    report("frank@example.com", "Frank high.", severity: 2)
    report("grace@example.com", "Grace low.", severity: 0)
    expect(Escalation.count).to eq(0)
    expect(Feedback.find_by!(comments: "Grace low.").priority).to eq(0)
  end

  it "counts archived feedback and does not update it" do
    old_book = version!(game, number: 1, status: 1)
    historical = report("helen@example.com", "Helen on the old book.", book: old_book)
    old_book.update_columns(status: 2)
    report("carol@example.com", "Carol on combat.")
    report("frank@example.com", "Frank on combat.")

    expect(Escalation.where(rule_module: combat, severity: 2).count).to eq(1)
    expect(Feedback.find_by!(comments: "Carol on combat.").priority).to eq(1)
    expect(historical.reload.priority).to eq(0)
    expect(historical.escalation_id).to be_nil
    expect(historical.comments).to eq("Helen on the old book.")
  end
end
