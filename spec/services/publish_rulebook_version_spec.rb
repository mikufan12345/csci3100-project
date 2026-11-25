# frozen_string_literal: true

require "rails_helper"

# Red until app/services/publish_rulebook_version.rb exists.
# The call contract is:
#   PublishRulebookVersion.new(version:, deprecate_module_ids:, replacements:).call
# replacements maps a module id (String) to the replacement module id.
RSpec.describe "PublishRulebookVersion" do
  let(:studio) { studio!("Neon Dice Co.") }
  let(:carol) { member!(studio, User::PLAYTESTER, "carol@example.com") }
  let(:frank) { member!(studio, User::PLAYTESTER, "frank@example.com") }
  let(:game) { game!(studio) }
  let(:combat) { mod!(game, "Combat") }
  let(:magic) { mod!(game, "Magic") }
  let(:current) { version!(game, number: 1, status: 1) }
  let(:draft) { version!(game, number: 2, status: 0) }

  def publish(deprecate_module_ids: [], replacements: {})
    PublishRulebookVersion.new(
      version: draft,
      deprecate_module_ids: deprecate_module_ids,
      replacements: replacements
    ).call
  end

  it "archives the previous public version and leaves one public version" do
    current
    publish
    expect(current.reload.status).to eq(2)
    expect(draft.reload.status).to eq(1)
    expect(game.rulebook_versions.where(status: 1).count).to eq(1)
  end

  it "stamps eligible older feedback when a module is deprecated and does not touch comments" do
    combat_note = feedback!(
      session!(carol, current),
      combat,
      comments: "Combat takes too many dice.",
      status: 0
    )
    confirmed = feedback!(
      session!(frank, current),
      combat,
      comments: "The timing window is wrong.",
      status: 1
    )
    intended = feedback!(
      session!(frank, current),
      magic,
      comments: "This rule works at the table.",
      status: 2,
      severity: 0
    )

    publish(deprecate_module_ids: [combat.id])

    expect(combat_note.reload.status).to eq(3)
    expect(confirmed.reload.status).to eq(3)
    expect(intended.reload.status).to eq(2)
    expect(combat_note.reload.comments).to eq("Combat takes too many dice.")
    expect(confirmed.reload.comments).to eq("The timing window is wrong.")
    expect(intended.reload.comments).to eq("This rule works at the table.")
    expect(Feedback.count).to eq(3)
  end

  it "stamps eligible feedback when a module is replaced" do
    note = feedback!(session!(carol, current), combat, comments: "Combat takes too many dice.", status: 0)
    publish(replacements: { combat.id.to_s => magic.id })
    expect(note.reload.status).to eq(3)
    expect(note.reload.comments).to eq("Combat takes too many dice.")
  end

  it "does not stamp feedback when nothing is deprecated or replaced" do
    note = feedback!(session!(carol, current), combat, comments: "Combat takes too many dice.", status: 0)
    publish
    expect(note.reload.status).to eq(0)
  end

  it "leaves an existing re_evaluation stamp and its comments alone" do
    stamped = feedback!(session!(carol, current), combat, comments: "Already stamped.", status: 3, severity: 1)
    publish(deprecate_module_ids: [combat.id])
    expect(stamped.reload.status).to eq(3)
    expect(stamped.reload.comments).to eq("Already stamped.")
  end
end
