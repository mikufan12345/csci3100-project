FactoryBot.define do
  factory :feedback do
    status { 0 }
    comments { "The combat round runs too long." }
    playtest_session

    after(:build) do |feedback|
      game = feedback.playtest_session.rulebook_version.game_project
      feedback.rule_module ||= build(:rule_module, game_project: game)
    end
  end
end
