class AddGptaskIdToIssues < ActiveRecord::Migration
  def self.up
    add_column :issues, :gptask_id, :integer
    add_column :issues, :predecessor_id, :integer
    add_column :issues, :parent_id, :integer
    add_column :gp_tasks, :predecessor_id, :integer
  end

  def self.down
    remove_column :issues, :parent_id
    remove_column :gp_tasks, :predecessor_id
    remove_column :issues, :predecessor_id
    remove_column :issues, :gptask_id
  end
end
