require 'rexml/document'

class SyncController < ApplicationController
  unloadable
  before_filter :find_project, :authorize
  
  def sync
    task = GpTask.find(:first) if params[:tracker_id].nil?
    params[:tracker_id] = task.tracker_id unless task.nil?

    if (!params[:tracker_id].nil?)
      @issues = GpTask.find(:all, :conditions => { :parent_id => nil, :tracker_id => params[:tracker_id] })
      @tracker = Tracker.find params[:tracker_id]
    else
      @issues = {}
    end
    render :partial => 'sync_form', :layout => false if request.xml_http_request?
  end

  def import
    if (params[:delete_unsynced] == 1)
      GpTask.delete_all("project_id=#{@project.id} AND tracker_id=#{params[:tracker_id]}")
    end
    import_ganttproject_file(File.new(params[:ganttprojectfile].path), params[:tracker_id])
    flash[:notice] = l(:import_success)
    redirect_to :action => 'sync', :project_id=>params[:project_id]
  end

  def apply
    # synchronize the selected tasks
    @tracker = Tracker.find(params[:tracker_id])
    
    issues_found = []
    predecessor_map = {}

    Issue.transaction do
      params.keys.grep(/^task\d+$/).each do |task_param|
        next if params[task_param].to_i != 1
        task = GpTask.find(task_param.scan(/(\d+)/).first.first)

        # try updating the issue if it exists, otherwise create a new one
        issue = Issue.find_by_project_id_and_tracker_id_and_gptask_id(@project.id, task.tracker_id, task.gp_id) || Issue.new
        unless issue.new_record?
          issues_found << issue.id
        end
        issue.tracker_id = task.tracker_id
        issue.project_id = task.project_id
        issue.gptask_id = task.gp_id
        issue.start_date = task.start
        issue.due_date = task.end_date
        issue.done_ratio = task.complete
        issue.subject = task.name
        issue.author = User.current unless issue.author
        case task.priority
          when 0:
            issue.priority = IssuePriority.find_by_name 'Low'
          when 1:
            issue.priority = IssuePriority.find_by_name 'Normal'
          when 2:
            issue.priority = IssuePriority.find_by_name 'High'
        end
        #issue.description = task.notes unless gpTask.notes.empty?
        issue.predecessor_id = nil
        parent_issue = Issue.find_by_project_id_and_tracker_id_and_gptask_id(@project.id, @tracker.id, task.parent_id) unless task.parent_id.nil?
        issue.parent_issue_id = parent_issue.id unless parent_issue.nil?
        #issue.move_to_root
        issue.save!

        predecessor_map[issue.id] = task.predecessor_id unless task.predecessor_id.nil?
        #parent_map[issue.id] = task.parent_id unless task.parent_id.nil?

        task.destroy
      end

      #assign_child_relationship(parent_map)
      assign_predecessor_relationship(predecessor_map)
    end

    if (params[:delete_unchecked].to_i == 1)
      GpTask.delete_all("project_id=#{@project.id} AND tracker_id=#{params[:tracker_id]}")
    end
    if (params[:delete_unmatched].to_i == 1 && !issues_found.empty?)
      Issue.delete_all("project_id=#{@project.id} AND tracker_id=#{params[:tracker_id]} AND id NOT IN (#{issues_found.join(',')})")
    end
    flash[:notice] = l(:sync_success)
    redirect_to :controller => 'issues', :action => 'index', :project_id=>params[:project_id]
  end
  
  private
 
  def find_project
    # @project variable must be set before calling the authorize filter
    @project = Project.find(params[:project_id])
  end
  
  def import_ganttproject_file(gp_file, tracker_id)
    doc = REXML::Document.new(gp_file)
    dependency_map = {}

    default_calendar = doc.root.find_first_recursive {|node| node.kind_of? REXML::Element and node.name == 'default-week'}
    unless default_calendar.nil?
      @weekdays = default_calendar.attributes.collect{|attribute,value| value.to_i }
    else
      @weekdays = [1,0,0,0,0,0,1] # assume default
    end

    GpTask.transaction do
      doc.elements.each('//task') do |element|
        # if there is already a pending task with the same id, overwrite it with new information
        existing_task = GpTask.find_by_project_id_and_tracker_id_and_gp_id(@project.id, tracker_id, element.attribute('id').value)
        existing_task.destroy unless existing_task.nil?

        gp_task = GpTask.new
        gp_task.project_id = @project.id
        gp_task.tracker_id = tracker_id
        gp_task.gp_id = element.attribute('id').value
        gp_task.name = element.attribute('name').value
        gp_task.start = element.attribute('start').value
        gp_task.duration = element.attribute('duration').value
        gp_task.end_date = calculate_real_end_date(gp_task.start, gp_task.duration)
        gp_task.complete = element.attribute('complete').value
        gp_task.priority = element.attribute('priority').value

        if (dependency_map.key?(gp_task.gp_id))
          gp_task.predecessor_id = dependency_map[gp_task.gp_id]
        end

        element.each_element('depend') do |dependency_element|
          dependency_map[dependency_element.attribute('id').value.to_i]=gp_task.gp_id
        end
        if (element.parent.name == 'task')
          gp_task.parent_id = GpTask.find_by_project_id_and_tracker_id_and_gp_id(@project.id, tracker_id, element.parent.attribute('id').value).gp_id
        end
        gp_task.save
      end
    end
  end

  def calculate_real_end_date(start_date, duration)
    current_wday = start_date.wday
    end_date = start_date+1
    (duration-1).times do
      end_date += (@weekdays[current_wday] == 0 ? 1 : 2)
      current_wday = (current_wday + 1) % 7
    end
    end_date
  end
  
  def assign_predecessor_relationship(relationship_map)
    relationship_map.each do |issue_id, task_id|
      related_issue = Issue.find_by_project_id_and_tracker_id_and_gptask_id(@project.id, @tracker.id, task_id)
      next if related_issue.nil? # task not found, maybe it wasn't selected for synchronization
      issue = Issue.find(issue_id)
      issue.predecessor_id = related_issue.id
      issue.save
    end
  end
end
