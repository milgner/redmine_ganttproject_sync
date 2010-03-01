require 'redmine'

Redmine::Plugin.register :redmine_ganttproject_sync do
  name 'Redmine GanttProject Synchronization plugin'
  author 'Marcus Ilgner <mail@marcusilgner.com>'
  description 'Synchronizes a Redmine issue tracker with data from a GanttProject file'
  version '0.0.1'
end
