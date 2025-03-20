# frozen_string_literal: true

require "test_helper"

module JobBuffer
  class << self
    def clear
      values.clear
    end

    def add(value)
      values << value
    end

    def values
      @values ||= []
    end

    def last_value
      values.last
    end
  end
end

class DisableLogJob < ActiveJob::Base
  self.log_arguments = false

  def perform(dummy)
    logger.info "Dummy, here is it: #{dummy}"
  end
end

class HelloJob < ActiveJob::Base
  def perform(greeter="David")
    JobBuffer.add("#{greeter} says hello")
  end
end

class DelayedJobAdapterTest < ActiveSupport::TestCase
  teardown do
    JobBuffer.clear
  end

  test "does not log arguments when log_arguments is set to false on a job" do
    job_id = SecureRandom.uuid

    job_wrapper = ActiveJob::QueueAdapters::DelayedJobAdapter::JobWrapper.new(
      "job_class" => DisableLogJob.to_s,
      "queue_name" => "default",
      "job_id" => job_id,
      "arguments" => { "some" => { "job" => "arguments" } }
    )

    assert_equal "DisableLogJob [#{job_id}] from DelayedJob(default)", job_wrapper.display_name
  end

  test "logs arguments when log_arguments is set to true on a job" do
    job_id = SecureRandom.uuid
    arguments = { "some" => { "job" => "arguments" } }

    job_wrapper = ActiveJob::QueueAdapters::DelayedJobAdapter::JobWrapper.new(
      "job_class" => HelloJob.to_s,
      "queue_name" => "default",
      "job_id" => job_id,
      "arguments" => arguments
    )

    assert_equal "HelloJob [#{job_id}] from DelayedJob(default) with arguments: #{arguments}",
                 job_wrapper.display_name
  end

  test "shows name for invalid job class" do
    job_id = SecureRandom.uuid

    job_wrapper = ActiveJob::QueueAdapters::DelayedJobAdapter::JobWrapper.new(
      "job_class" => "NotExistingJob",
      "queue_name" => "default",
      "job_id" => job_id,
      "arguments" => { "some" => { "job" => "arguments" } }
    )

    assert_equal "NotExistingJob [#{job_id}] from DelayedJob(default)", job_wrapper.display_name
  end

  test "perform_now" do
    HelloJob.perform_now("Alex")
    assert_equal ["Alex says hello"], JobBuffer.values.sort
  end

  test "perform_later" do
    HelloJob.perform_later("Alex")
    assert_equal ["Alex says hello"], JobBuffer.values.sort
  end

  test "insert_all_later" do
    ActiveJob.perform_all_later([HelloJob.new("Jamie"), HelloJob.new("John")])

    assert_equal ["Jamie says hello", "John says hello"], JobBuffer.values.sort
  end
end
