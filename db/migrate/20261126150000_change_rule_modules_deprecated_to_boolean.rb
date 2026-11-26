# docs/refined_proposal.md: `deprecated` is a boolean with default false,
# null false. The integer column from the first migration is replaced, not
# overloaded with 0 and 1. Backfill: existing 1s stay true, NULL/0 become
# false, so a never-touched module can still be deprecated on publish.
# PostgreSQL will not cast integer to boolean automatically, so the type
# change carries an explicit USING clause (the backfill above guarantees
# only 0 and 1 values are present).
class ChangeRuleModulesDeprecatedToBoolean < ActiveRecord::Migration[7.1]
  def change
    reversible do |direction|
      direction.up do
        execute "UPDATE rule_modules SET deprecated = COALESCE(deprecated, 0)"
        execute "ALTER TABLE rule_modules ALTER COLUMN deprecated TYPE boolean USING (deprecated <> 0)"
        change_column_default :rule_modules, :deprecated, from: nil, to: false
        change_column_null :rule_modules, :deprecated, false, false
      end
      direction.down do
        change_column_null :rule_modules, :deprecated, true
        change_column_default :rule_modules, :deprecated, from: false, to: nil
        execute "ALTER TABLE rule_modules ALTER COLUMN deprecated TYPE integer USING (deprecated::integer)"
      end
    end
  end
end