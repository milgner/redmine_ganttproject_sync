class AddEndDateToGptasks < ActiveRecord::Migration
  def self.up
    add_column :gp_tasks, :end_date, :date
  end

  def self.down
    remove_column :gp_tasks, :end_date
  end
end
