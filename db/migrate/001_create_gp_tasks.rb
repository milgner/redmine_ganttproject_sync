class CreateGpTasks < ActiveRecord::Migration
  def self.up
    create_table :gp_tasks do |t|
      t.column :project_id, :string
      t.column :gp_id, :integer
      t.column :tracker_id, :integer
      t.column :parent_id, :integer
      t.column :name, :string
      t.column :start, :date
      t.column :duration, :integer
      t.column :complete, :integer
      t.column :priority, :integer
    end
  end

  def self.down
    drop_table :gp_tasks
  end
end
