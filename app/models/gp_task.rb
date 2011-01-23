class GpTask < ActiveRecord::Base
  belongs_to :tracker
  belongs_to :project

  belongs_to :parent, :class_name => 'GpTask', :primary_key => 'gp_id'  
  has_many :children, :class_name => 'GpTask', :finder_sql => 'SELECT DISTINCT gp_tasks.* FROM gp_tasks ' +
                                                                'WHERE project_id=#{project_id} ' +
                                                                'AND tracker_id=#{tracker_id} ' +
                                                                'AND parent_id=#{gp_id}'

  belongs_to :predecessor, :class_name => 'GpTask', :primary_key => 'gp_id'  
  has_many :dependants, :class_name => 'GpTask', :finder_sql => 'SELECT DISTINCT gp_tasks.* FROM gp_tasks ' +
                                                              'WHERE project_id=#{project_id} ' +
                                                              'AND tracker_id=#{tracker_id} ' +
                                                              'AND predecessor_id=#{gp_id}'

  def to_s
    "#{id} - #{name}"
  end
end
