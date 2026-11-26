class AddReplacedByToRuleModules < ActiveRecord::Migration[7.1]
  def change
    add_reference :rule_modules, :replaced_by, foreign_key: { to_table: :rule_modules }
  end
end