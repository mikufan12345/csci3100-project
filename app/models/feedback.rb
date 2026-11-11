class Feedback < ApplicationRecord
  belongs_to :playtest_session
  belongs_to :rule_module
end
