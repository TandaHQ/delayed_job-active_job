# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)
require "delayed_job/active_job"

require "minitest/autorun"
Dir[File.expand_path("support/**/*.rb", __dir__)].each { |rb| require(rb) }

ActiveJob::Base.queue_adapter = :delayed_job
Delayed::Worker.delay_jobs = false
Delayed::Worker.backend = :test

# activate ~/lib/delayed_job/active_job/run_at.rb
ActiveJob::Base.include(ActiveJob::RunAt)
