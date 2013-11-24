require_relative 'builds_database'
require_relative 'jenkins_connector'

class AppConfig
  attr_reader :gitlab_url, :jenkins_url, :db_url
  attr_reader :db, :jenkins

  def initialize(gitlab_url, jenkins_url, db_url)
    @gitlab_url = gitlab_url
    @jenkins_url = jenkins_url
    @db_url = db_url

    @db_connection = Sequel.connect db_url
    @db = BuildsDatabase.new @db_connection
    @jenkins = JenkinsConnector.new jenkins_url
  end
end
