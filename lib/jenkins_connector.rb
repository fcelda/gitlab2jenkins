require "jenkins_api_client"
require_relative "jenkins_api_extension"

class JenkinsConnector
  def initialize(server_url)
    @jenkins = JenkinsApi::Client.new server_url: server_url
  end

  def submit_build(job, commit, branch)
    @jenkins.job.build_with_token(job.name, job.jenkins_token, { :commit => commit, :branch => branch })
  end

  def refresh_builds(job)
    builds = @jenkins.job.get_builds job.name
    builds.each do |build|
      refresh_build job, build["number"]
    end
  end

  private

  def refresh_build(job, build_number)
    build = job.builds_dataset.first(build: build_number)

    # nothing new to update
    return if build and final_status?(build.status)

    # download build details
    build_details = @jenkins.job.get_build_details(job.name, build_number)
    build_info = extract_build_info(build_details)

    # commit number not specified or not in complete form
    return if build_info[:commit].nil?

    # try to find submitted build without build number assigned
    if build.nil?
      build = job.builds_dataset.first(commit: build_info[:commit], build: nil)
    end

    if build.nil?
      create_new_build job, build_info
    elsif not final_status?(build.status)
      update_existing_build job, build_info, build
    end
  end

  def create_new_build(job, info)
    build = job.add_build(info)
    build.save
  end

  def update_existing_build(job, info, build)
    build.build  = info[:build]
    build.status = info[:status]
    build.branch = info[:branch] if build.branch.nil?
    build.save
  end

  def extract_build_info(data)
    result = {
      :build => data["number"],
      :status => build_status_from_api(data["result"]),
      :created_at => nil,
      :commit => nil,
      :branch => nil
    }

    if not data["timestamp"].nil?
      result[:created_at] = Time.at(data["timestamp"] / 1000)
    end

    fallback = {:commit => nil, :branch => nil}

    data["actions"].each do |action|
      if action.has_key?("lastBuiltRevision")

        last_built_revision = action["lastBuiltRevision"]
        result[:commit] = last_built_revision["SHA1"]

        last_built_revision["branch"].each do |branch_info|
          if branch_info["SHA1"] == result[:commit]
            result[:branch] = branch_info["name"] unless branch_info["name"] == "detached"
            break
          end
        end
        break

      elsif action.has_key?("parameters")
        action["parameters"].each do |parameter|
           fallback[:commit] = parameter["value"] if parameter["name"] == "commit"
           fallback[:branch] = parameter["value"] if parameter["name"] == "branch"
        end
      end
    end

    if result[:commit].nil? and fallback[:commit] =~ /^[0-9a-f]{40}$/
      result[:commit] = fallback[:commit]
    end

    if result[:branch].nil? and not fallback[:branch].nil?
      result[:branch] = fallback[:branch]
    end

    result
  end

  def build_status_from_api(api_string)
    if api_string.nil?
      nil
    else
      case api_string.downcase
        when "success" then "success"
        when "aborted" then "canceled"
        when "running" then "running"
        else "failed"
      end
    end
  end

  def final_status?(status)
    ["success", "canceled", "failed"].include? status
  end

end
