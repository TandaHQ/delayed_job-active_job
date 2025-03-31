# frozen_string_literal: true

# copied from https://github.com/collectiveidea/delayed_job/blob/master/spec/delayed/backend/test.rb

# An in-memory backend suitable only for testing. Tries to behave as if it were an ORM.
module Delayed
  module Backend
    module Test
      class Job
        attr_accessor :id,
                      :priority,
                      :attempts,
                      :handler,
                      :last_error,
                      :run_at,
                      :locked_at,
                      :locked_by,
                      :failed_at,
                      :queue,
                      :metadata # for testing job_attributes

        include Delayed::Backend::Base

        cattr_accessor :id, default: 0, instance_accessor: false

        def initialize(hash={})
          self.attempts = 0
          self.priority = 0
          self.id = (self.class.id += 1)
          hash.each { |k, v| send(:"#{k}=", v) }
        end

        @jobs = []
        def self.all
          @jobs
        end

        def self.count
          all.size
        end

        def self.delete_all
          all.clear
        end

        def self.create(attrs={})
          new(attrs).tap(&:save)
        end

        def self.create!(*args) = create(*args)

        def self.clear_locks!(worker_name)
          all.select { |j| j.locked_by == worker_name }.each do |j|
            j.locked_by = nil
            j.locked_at = nil
          end
        end

        # Find a few candidate jobs to run (in case some immediately get locked by others).
        def self.find_available(worker_name, limit=5, max_run_time=Worker.max_run_time)
          jobs = all.select do |j|
            j.run_at <= db_time_now &&
              (j.locked_at.nil? || j.locked_at < db_time_now - max_run_time || j.locked_by == worker_name) &&
              !j.failed?
          end

          jobs = jobs.select { |j| Worker.queues.include?(j.queue) }   if Worker.queues.any?
          jobs = jobs.select { |j| j.priority >= Worker.min_priority } if Worker.min_priority
          jobs = jobs.select { |j| j.priority <= Worker.max_priority } if Worker.max_priority
          jobs.sort_by { |j| [j.priority, j.run_at] }[0..limit - 1]
        end

        def self.insert_all(attributes)
          attributes.each { |a| create(a) }
        end

        # Lock this job for this worker.
        # Returns true if we have the lock, false otherwise.
        def lock_exclusively!(_max_run_time, worker)
          now = self.class.db_time_now
          if locked_by != worker
            # We don't own this job so we will update the locked_by name and the locked_at
            self.locked_at = now
            self.locked_by = worker
          end

          true
        end

        def self.db_time_now
          Time.current
        end

        def update_attributes(attrs={})
          attrs.each { |k, v| send(:"#{k}=", v) }
          save
        end

        def destroy
          self.class.all.delete(self)
        end

        def save
          self.run_at ||= Time.current

          self.class.all << self unless self.class.all.include?(self)
          true
        end

        def save! = save

        def reload
          reset
          self
        end

        def attributes
          instance_variables.to_h do |ivar|
            [ivar.to_s.delete("@"), instance_variable_get(ivar)]
          end
        end
      end
    end
  end
end
