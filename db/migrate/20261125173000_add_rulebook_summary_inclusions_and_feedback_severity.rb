class AddRulebookSummaryInclusionsAndFeedbackSeverity < ActiveRecord::Migration[7.1]
  def change
    add_column :rulebook_versions, :summary, :text
    add_column :feedbacks, :severity, :integer

    create_table :rulebook_inclusions do |t|
      t.references :rulebook_version, null: false, foreign_key: true
      t.references :rule_module, null: false, foreign_key: true
      t.timestamps
    end

    add_index :rulebook_inclusions,
              [:rulebook_version_id, :rule_module_id],
              unique: true,
              name: "index_rulebook_inclusions_on_version_and_module"
  end
end
