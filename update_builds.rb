#!/usr/bin/env ruby

if ARGV.count != 1 or not ["once", "loop"].include?(ARGV[0])
  STDERR.puts "usage: %s (once|loop)" % $PROGRAM_NAME
  exit 1
end

require_relative './config'

POLL_TIMEOUT = 30
ERROR_TIMEOUT = 600
infinite = ARGV[0] == "loop"

while true do
  error = false
  CONFIG.db.job.each do |job|
    begin
      CONFIG.jenkins.refresh_builds(job)
    rescue Exception => e
      error = true
      STDERR.puts "Exception: #{e.to_s}"
    end
  end

  break unless infinite
  if error
    sleep ERROR_TIMEOUT
  else
    sleep POLL_TIMEOUT
  end

end
