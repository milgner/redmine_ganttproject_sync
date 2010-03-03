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
    flash[:notice] = l(:sync_success)
    redirect_to :action => 'sync', :project_id=>params[:project_id]
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
        logger.debug("found element in dependency map: #{gpTask.gp_id}")
        gpTask.predecessor_id = dependencyMap[gpTask.gp_id]
      end
      
      element.each_element('depend') do |depencyElement|
        logger.debug("found dependency #{depencyElement}")
        dependencyMap[depencyElement.attribute('id').value.to_i]=gpTask.gp_id
      end
      
      if (element.parent.name == 'task')
        gpTask.parent = GpTask.find_by_project_id_and_tracker_id_and_gp_id(@project.id, tracker_id, element.parent.attribute('id').value)
        logger.debug("set parent task to #{gpTask.parent}")
      end
      gpTask.save
    end
  end
end
