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

class CallbackJob < ActiveJob::Base
  before_perform :say_hi_before_perform
  before_enqueue :say_hi_before_enqueue

  def perform(greeter)
    JobBuffer.add("#{greeter} says hello in perform")
  end

  private

  def say_hi_before_perform
    JobBuffer.add("job says hello before perform")
  end

  # This is NOT called when using perform_all_later, per https://github.com/rails/rails/pull/46603
  def say_hi_before_enqueue
    JobBuffer.add("job says hello before enqueue")
  end
end

class DelayedJobAdapterTest < ActiveSupport::TestCase
  teardown do
    Delayed::Job.delete_all
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
    assert_equal ["Alex says hello"], JobBuffer.values
  end

  test "perform_later" do
    HelloJob.perform_later("Alex")
    assert_equal ["Alex says hello"], JobBuffer.values
  end

  test "insert_all_later" do
    ActiveJob.perform_all_later([HelloJob.new("Jamie"), HelloJob.new("John"), CallbackJob.new("Alex")])

    assert_equal ["Jamie says hello", "John says hello", "job says hello before perform", "Alex says hello in perform"], JobBuffer.values
  end

  test "run_at with enqueue" do
    Delayed::Worker.delay_jobs = true

    HelloJob.perform_later("Alex")
    assert_empty JobBuffer.values
    run_at = Delayed::Job.all.first.run_at
    assert_in_delta run_at, Time.current, 0.01
  ensure
    Delayed::Worker.delay_jobs = false
  end

  test "run_at with enqueue_at" do
    Delayed::Worker.delay_jobs = true

    expected = 2.days.from_now
    HelloJob.set(wait_until: expected).perform_later("Alex")
    assert_empty JobBuffer.values
    run_at = Delayed::Job.all.first.run_at
    assert_in_delta run_at, expected, 0.01
  ensure
    Delayed::Worker.delay_jobs = false
  end

  test "run_at with insert_all_later" do
    Delayed::Worker.delay_jobs = true

    expected = 2.days.from_now
    job = HelloJob.new("Alex")
    job.run_at = expected
    ActiveJob.perform_all_later([job])
    assert_empty JobBuffer.values
    run_at = Delayed::Job.all.first.run_at
    assert_in_delta run_at, expected, 0.01
  ensure
    Delayed::Worker.delay_jobs = false
  end

  test "implicit run_at with insert_all_later" do
    Delayed::Worker.delay_jobs = true

    job = HelloJob.new("Alex")
    ActiveJob.perform_all_later([job])
    assert_empty JobBuffer.values
    run_at = Delayed::Job.all.first.run_at
    assert_in_delta run_at, Time.new, 0.01
  ensure
    Delayed::Worker.delay_jobs = false
  end

  test "job attributes with enqueue" do
    Delayed::Worker.delay_jobs = true

    job = HelloJob.new("Alex")
    job.job_attributes = { metadata: "foo" }
    job.enqueue

    assert_equal "foo", Delayed::Job.all.first.metadata
  ensure
    Delayed::Worker.delay_jobs = false
  end

  test "job attributes with enqueue_at" do
    Delayed::Worker.delay_jobs = true

    job = HelloJob.new("Alex")
    job.set(wait_until: 2.days.from_now)
    job.job_attributes = { metadata: "foo" }
    job.enqueue

    assert_equal "foo", Delayed::Job.all.first.metadata
  ensure
    Delayed::Worker.delay_jobs = false
  end

  test "job attributes with insert_all_later" do
    Delayed::Worker.delay_jobs = true

    job = HelloJob.new("Alex")
    job.job_attributes = { metadata: "foo" }
    ActiveJob.perform_all_later([job])

    assert_equal "foo", Delayed::Job.all.first.metadata
  ensure
    Delayed::Worker.delay_jobs = false
  end
end
