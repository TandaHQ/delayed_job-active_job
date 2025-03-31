# frozen_string_literal: true

module ActiveJob
  # Includes the ability to override when a job should run.
  module RunAt
    extend ActiveSupport::Concern
    included do
      class_attribute :run_at, instance_writer: true, instance_accessor: false, default: -> { Time.current }
    end

    def run_at
      @run_at = instance_exec(&@run_at) if @run_at.is_a?(Proc)
      @run_at
    end
  end
end

ActiveSupport.on_load(:active_job) do
  include ActiveJob::RunAt
end
