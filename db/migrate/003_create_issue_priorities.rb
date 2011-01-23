class CreateIssuePriorities < ActiveRecord::Migration
  def self.up
    IssuePriority.create(:name => 'Low') unless IssuePriority.find_by_name('Low')
    IssuePriority.create(:name => 'Normal', :is_default => true) unless IssuePriority.find_by_name('Normal')
    IssuePriority.create(:name => 'High') unless IssuePriority.find_by_name('High')
  end

  def self.down
  end
end
