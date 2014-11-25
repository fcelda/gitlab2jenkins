#!/usr/bin/env ruby

require 'json'
require 'sinatra'

require_relative './config'
$db = CONFIG.db
$jenkins = CONFIG.jenkins

configure :production, :development do
  enable :logging
  set :gitlab_url, CONFIG.gitlab_url
  set :jenkins_url, CONFIG.jenkins_url
end

# UI calls

get '/' do
  haml :index, locals: { jobs: $db.job.all }
end

get '/projects/:job_id' do
  job_id = params[:job_id].to_i
  job = $db.job[job_id]
  halt 404 if job.nil?

  haml :project, locals: { job: job, builds: job.builds_dataset.reverse_order(:created_at).limit(30).all }
end

get '/projects/:job_id/commits/:commit' do
  job_id = params[:job_id].to_i
  commit = params[:commit]

  builds = $db.build.filter(job_id: job_id, commit: commit).reverse_order(:created_at).all
  halt 404 if builds.empty?

  haml :build, locals: {
    commit: commit,
    branch: builds.first.branch,
    status: builds.first.status,
    builds: builds,
    job: builds.first.job,
  }
end

get '/projects/:job_id/status.png' do
  ref = request.params["ref"]
  halt 404 if ref.nil?

  job_id = params[:job_id].to_i
  job = $db.job[job_id]
  halt 404 if job.nil?

  last_build = job.builds_dataset.reverse_order(:created_at).first(branch: ref)
  status = last_build && last_build.status

  image = case status
    when "success"  then "success.png"
    when "failed"   then "failed.png"
    when "canceled" then "failed.png"
    when "running"  then "running.png"
    else "unknown.png"
  end

  redirect "/#{image}", 303
end

# API calls

get '/projects/:job_id/commits/:commit/status.json' do
  job_id = params[:job_id].to_i
  commit = params[:commit]
  token = request.params["token"]
  content_type :json

  job = $db.job.get_authenticated(job_id, token)
  halt 403, { "error" => "invalid token" }.to_json if job.nil?

  commit = job.builds_dataset.reverse_order(:created_at).first(:commit => commit)
  halt 404, { "error" => "commit not found" }.to_json if commit.nil?

  # https://github.com/gitlabhq/gitlabhq/blob/master/app/views/projects/merge_requests/show/_mr_ci.html.haml
  # success, failed, running, pending

  if commit.status.nil?
    status = "running"
  elsif ["success", "failed", "running"].include? commit.status
    status = commit.status
  else
    status = "failed"
  end

  logger.info("returned status for %s is %s" % [commit, status])

  { "status" => status }.to_json
end

post '/projects/:job_id/build' do
  job_id = params[:job_id].to_i
  token = request.params["token"]
  force = request.params["force"] == "true"
  content_type :json

  job = $db.job.get_authenticated(job_id, token)
  halt 403, { "error" => "invalid token" }.to_json if job.nil?

  begin
    data = JSON.parse(request.body.read)
  rescue Exception => e
    halt 404, { "error" => e.to_s}.to_json
  end

  logger.debug(data)

  commit = data["after"]
  if commit.nil? or not commit =~ /^[0-9a-z]{7,40}$/
    halt 404, { "error" => "invalid commit (after value)" }.to_json
  end

  # ignore builds for zero commit (0000000)
  if commit =~ /^0+$/
    halt 200, true.to_json
  end

  # do not restart the build for existing commits
  if not force and not $db.build.first(job_id: job_id, commit: commit).nil?
    logger.info("build for commit %s already exists" % commit)
    halt 200
  end

  branch = data["ref"]
  branch.sub!(/^refs\/heads\//, "") unless branch.nil?

  new_build = $db.build.new(job_id: job_id, commit: commit, branch: branch)

  begin
    $jenkins.submit_build(job, commit, branch)
  rescue Exception => e
    logger.error("Failed to submit build for %s, commit %s (%s)." % [job.name, commit, e.to_s]);
    halt 503, { "error" => "Cannot submit build to Jenkins server." }.to_json
  end

  new_build.save
  halt 200
end

post '/projects/:job_id/refresh' do
  job_id = params[:job_id].to_i
  token = request.params["token"]

  job = $db.job.get_authenticated(job_id, token)
  halt 403, { "error" => "invalid token" }.to_json if job.nil?

  $jenkins.refresh_builds(job)
end
