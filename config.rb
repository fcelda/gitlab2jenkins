require_relative 'lib/app_config'

#ENV["TZ"] = "Europe/Prague"

if ENV.include? 'OPENSHIFT_APP_UUID'
  db_url = ENV["OPENSHIFT_MYSQL_DB_URL"].sub(/^mysql:/, "mysql2:")
  db_url = File.join db_url, ENV["OPENSHIFT_APP_NAME"]
else
  db_url = "mysql2://gitlab2jenkins:password@localhost/gitlab2jenkins"
end

CONFIG = AppConfig.new(
  "https://gitlab.example.com",
  "https://jenkins.example.com",
  db_url
)
