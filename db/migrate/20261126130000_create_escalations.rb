class CreateEscalations < ActiveRecord::Migration[7.1]
  def change
    create_table :escalations do |t|
      t.references :rule_module, null: false
      t.integer :severity, null: false
      t.integer :priority, null: false, default: 0
      t.timestamps

      # One escalation per module and severity (Business Rule 3).
      t.index [:rule_module_id, :severity], unique: true
    end

    add_reference :feedbacks, :escalation
  end
end