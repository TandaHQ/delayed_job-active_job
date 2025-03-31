# frozen_string_literal: true

module ActiveJob
  # Includes the ability to store extra attributes on a job instance, that are persisted into the delayed_jobs table.
  module JobAttributes
    extend ActiveSupport::Concern
    included do
      class_attribute :job_attributes, instance_writer: true, instance_accessor: true, default: {}
    end
  end
end

ActiveSupport.on_load(:active_job) do
  include ActiveJob::JobAttributes
end
