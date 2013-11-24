require 'sequel'

class BuildsDatabase

  attr_reader :job, :build

  def initialize(db_connection)
    @db = db_connection
    create_schema

    require_relative "builds_model"
    @job = Job
    @build = Build
  end

  def create_schema
    create_jobs_table unless @db.table_exists?(:jobs)
    create_builds_table unless @db.table_exists?(:builds)
  end

  def create_jobs_table
    @db.create_table(:jobs) do
      column :id, :integer, :unsigned => true, :primary_key => true, :auto_increment => true
      column :name, :varchar, :length => 128, :null => false, :unique => true
      column :title, :varchar, :length => 128, :null => false
      column :token, :varchar, :length => 128, :null => false
      column :jenkins_token, :varchar, :length => 128, :null => false
    end
  end

  def create_builds_table
    @db.create_table(:builds) do
      column :id, :integer, :unsigned => true, :primary_key => true, :auto_increment => true
      foreign_key :job_id, :jobs, :type => :integer, :unsigned => true, :null => false, :on_delete => :restrict, :on_update => :cascade
      column :commit, :varchar, :length => 40, :null => false
      column :build, :integer, :null => true
      column :status, :varchar, :length => 128, :null => true
      column :created_at, :timestamp, :null => false, :default => Sequel::CURRENT_TIMESTAMP
      column :branch, :varchar, :length => 128, :null => true
    end
  end

end
