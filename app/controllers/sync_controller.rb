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
    @tracker = Tracker.find(params[:tracker_id])
    
    issues_found = []
    predecessor_map = {}
    parent_map = {}
    
    params.keys.grep(/^task\d+$/).each do |taskParam|
      next if params[taskParam].to_i != 1
      task = GpTask.find(taskParam.scan(/(\d+)/).first.first)
      
      # try updating the issue if it exists, otherwise create a new one
      issue = Issue.find_by_project_id_and_tracker_id_and_gptask_id(@project.id, task.tracker_id, task.gp_id) || Issue.new
      unless issue.new_record?
        issues_found << issue.id
      end
      issue.tracker_id = task.tracker_id
      issue.project_id = task.project_id
      issue.gptask_id = task.gp_id
      issue.start_date = task.start
      issue.due_date = task.start+task.duration.days
      issue.subject = task.name
      issue.author = User.current unless issue.author
      #issue.description = task.notes unless gpTask.notes.empty?
      issue.predecessor_id = nil
      issue.parent_id = nil
      issue.save!

      predecessor_map[issue.id] = task.predecessor_id unless task.predecessor_id.nil?
      parent_map[issue.id] = task.parent_id unless task.parent_id.nil?

      task.destroy
    end
    
    assign_relationship(predecessor_map, 'predecessor_id')
    assign_relationship(parent_map, 'parent_id')
    
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
  
  def import_ganttproject_file(gpfile, tracker_id)
    doc = REXML::Document.new(gpfile)
    dependencyMap = {}
    doc.elements.each('//task') do |element|
      # if there is already a pending task with the same id, overwrite it with new information
      existingTask = GpTask.find_by_project_id_and_tracker_id_and_gp_id(@project.id, tracker_id, element.attribute('id').value)
      existingTask.destroy unless existingTask.nil?
      
      gpTask = GpTask.new
      gpTask.project_id = @project.id
      gpTask.tracker_id = tracker_id
      gpTask.gp_id = element.attribute('id').value
      gpTask.name = element.attribute('name').value
      gpTask.start = element.attribute('start').value
      gpTask.duration = element.attribute('duration').value
      gpTask.complete = element.attribute('complete').value
      gpTask.priority = element.attribute('priority').value
      
      if (dependencyMap.key?(gpTask.gp_id))
        gpTask.predecessor_id = dependencyMap[gpTask.gp_id]
      end
      
      element.each_element('depend') do |depencyElement|
        dependencyMap[depencyElement.attribute('id').value.to_i]=gpTask.gp_id
      end
      if (element.parent.name == 'task')
        gpTask.parent_id = GpTask.find_by_project_id_and_tracker_id_and_gp_id(@project.id, tracker_id, element.parent.attribute('id').value).gp_id
      end
      gpTask.save
    end
  end
  
  def assign_relationship(relationship_map, attribute) 
    relationship_map.each do |issue_id, task_id|
      related_issue = Issue.find_by_project_id_and_tracker_id_and_gptask_id(@project.id, @tracker.id, task_id)
      next if related_issue.nil? # task not found, maybe it wasn't selected for synchronization
      issue = Issue.find(issue_id)
      issue.send("#{attribute}=", related_issue.id)
      issue.save
    end
  end
end
