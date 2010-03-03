class GpTask < ActiveRecord::Base
  belongs_to :tracker
  belongs_to :project

  belongs_to :parent, :class_name => 'GpTask'
  has_many :children, :class_name => 'GpTask', :foreign_key=>'parent_id'

  belongs_to :predecessor, :class_name => 'GpTask'
  has_many :dependants, :foreign_key=> 'predecessor_id', :class_name => 'GpTask'
  
  #def GpTask.top_level_tasks
  #  find(:all, :conditions => { :parent_id => nil })
  #end
end
