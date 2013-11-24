#!/usr/bin/env ruby

def usage
  STDERR.puts "usage: %s <display-name> <jenkins-name> <jenkins-token>" % $PROGRAM_NAME
end


if ARGV.count != 3
  usage
  exit 1
end

require 'rubygems'
require 'securerandom'
require_relative './config'

new_project = CONFIG.db.job.new

new_project.title = ARGV.shift
new_project.name = ARGV.shift
new_project.jenkins_token = ARGV.shift
new_project.token = SecureRandom.urlsafe_base64(32)

new_project.save

puts "Project: %s" % new_project.title
puts "Jenkins: %s (token %s)" % [new_project.name, new_project.jenkins_token]
puts "Token:   %s" % new_project.token
