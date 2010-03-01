class GpTask < ActiveRecord::Base
  belongs_to :parent, :class_name => 'GpTask'
  has_many :children, :class_name => 'GpTask', :foreign_key=>'parent_id'
  
  def GpTask.top_level_tasks
    find(:all, :conditions => { :parent_id => nil })
  end
end
