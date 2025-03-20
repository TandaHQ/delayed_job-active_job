# frozen_string_literal: true

require "test_helper"

module DelayedJob
  class ActiveJobTest < Minitest::Test
    def test_that_it_has_a_version_number
      refute_nil ::DelayedJob::ActiveJob::VERSION
    end
  end
end
