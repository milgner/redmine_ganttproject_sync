require 'rexml/document'

class SyncController < ApplicationController
  unloadable
  before_filter :find_project, :authorize
  
  def sync
    @issues = GpTask.top_level_tasks
  end

  def import
    logger.debug "File is: #{params[:ganttprojectfile].path}"
    import_ganttproject_file(File.new(params[:ganttprojectfile].path))
    flash[:notice] = l(:import_success)
    redirect_to :action => 'sync', :project_id=>params[:project_id]
  end

  def apply
  end
  
  private
 
  def find_project
    # @project variable must be set before calling the authorize filter
    @project = Project.find(params[:project_id])
  end
  
  def import_ganttproject_file(gpfile)
    doc = REXML::Document.new(gpfile)
    doc.elements.each('//task') do |element|
      # if there is already a pending task with the same id, overwrite it with new information
      existingTask = GpTask.find_by_project_id_and_gp_id(@project.id, element.attribute('id').value)
      existingTask.destroy unless existingTask.nil?
      
      gpTask = GpTask.new
      gpTask.project_id = @project.id
      gpTask.gp_id = element.attribute('id').value
      gpTask.name = element.attribute('name').value
      gpTask.start = element.attribute('start').value
      gpTask.duration = element.attribute('duration').value
      gpTask.complete = element.attribute('complete').value
      gpTask.priority = element.attribute('priority').value
      
      if (element.parent.name == 'task')
        gpTask.parent = GpTask.find_by_gp_id(element.parent.attribute('id').value)
      end
      gpTask.save
    end
  end
end
