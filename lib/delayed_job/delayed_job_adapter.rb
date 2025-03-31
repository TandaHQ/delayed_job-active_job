# frozen_string_literal: true

require "delayed_job"
require "active_job"
require "active_support/core_ext/string/inflections"

module ActiveJob
  module QueueAdapters
    # Override existing Rails adapter.
    remove_const :DelayedJobAdapter if constants.include?(:DelayedJobAdapter)

    # = Delayed Job adapter for Active Job
    #
    # Delayed::Job (or DJ) encapsulates the common pattern of asynchronously
    # executing longer tasks in the background. Although DJ can have many
    # storage backends, one of the most used is based on Active Record.
    # Read more about Delayed Job {here}[https://github.com/collectiveidea/delayed_job].
    #
    # To use Delayed Job, set the queue_adapter config to +:delayed_job+.
    #
    #   Rails.application.config.active_job.queue_adapter = :delayed_job
    class DelayedJobAdapter < ActiveJob::QueueAdapters::AbstractAdapter
      def enqueue(job)
        delayed_job = Delayed::Job.enqueue(JobWrapper.new(job.serialize), queue: job.queue_name, priority: job.priority, run_at: job.run_at)
        job.provider_job_id = delayed_job.id
        delayed_job
      end

      def enqueue_at(job, timestamp)
        delayed_job = Delayed::Job.enqueue(
          JobWrapper.new(job.serialize), queue: job.queue_name, priority: job.priority, run_at: job.run_at || Time.at(timestamp)
        )
        job.provider_job_id = delayed_job.id
        delayed_job
      end

      def enqueue_all(jobs)
        wrapped_jobs = jobs.filter_map do |job|
          options = Delayed::Backend::JobPreparer.new(JobWrapper.new(job.serialize), queue: job.queue_name, priority: job.priority, run_at: job.run_at).prepare
          job_to_enqueue = Delayed::Job.new(options)
          if Delayed::Worker.delay_job?(job_to_enqueue)
            job_to_enqueue
          else
            job_to_enqueue.invoke_job
            nil
          end
        end
        Delayed::Job.insert_all(wrapped_jobs)
      end

      class JobWrapper # :nodoc:
        attr_accessor :job_data

        def initialize(job_data)
          @job_data = job_data
        end

        def display_name
          base_name = "#{job_data['job_class']} [#{job_data['job_id']}] from DelayedJob(#{job_data['queue_name']})"

          return base_name unless log_arguments?

          "#{base_name} with arguments: #{job_data['arguments']}"
        end

        def perform
          Base.execute(job_data)
        end

        private

        def log_arguments?
          job_data["job_class"].constantize.log_arguments?
        rescue NameError
          false
        end
      end
    end
  end
end
