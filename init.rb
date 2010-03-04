require 'redmine'

Redmine::Plugin.register :redmine_ganttproject_sync do
  name 'Redmine GanttProject Synchronization plugin'
  author 'Marcus Ilgner <mail@marcusilgner.com>'
  description 'Synchronizes a Redmine issue tracker with data from a GanttProject file'
  version '0.0.1'
  
  project_module :ganttproject_sync do
    permission :synchronize_issues, :sync => [:sync, :import, :apply]
  end
  
  menu :project_menu, :ganttproject_sync, { :controller => 'sync', :action => 'sync' }, :caption => 'Ganttproject', :after => :issues, :param => :project_id  
  
  # extend the basic Redmine model with some new mojo
  # somehow this works in the console but not in the controller
  Issue.class_eval do 
    belongs_to :parent, :class_name => 'Issue'
    has_many :children, :class_name => 'Issue', :foreign_key=>'parent_id'

    belongs_to :predecessor, :class_name => 'Issue'
    has_many :dependants, :foreign_key=> 'predecessor_id', :class_name => 'Issue'
  end
  
end

