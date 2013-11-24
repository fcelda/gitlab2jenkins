require "jenkins_api_client"

module JenkinsApi
  class Client
    class Job
      def build_with_token(job_name, token, params={})
        msg = "Building job '#{job_name}' with token authentication"
        msg << " and parameters: #{params.inspect}" unless params.empty?
        @logger.info msg
        build_endpoint = params.empty? ? "build" : "buildWithParameters"
        raw_response = false
        @client.api_post_request(
          "/job/#{job_name}/#{build_endpoint}?token=#{token}",
          params,
          raw_response
        )
      end
    end
  end
end
