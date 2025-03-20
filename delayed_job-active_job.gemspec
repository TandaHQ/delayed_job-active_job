# frozen_string_literal: true

require_relative "lib/delayed_job/active_job/version"

Gem::Specification.new do |spec|
  spec.name = "delayed_job-active_job"
  spec.version = DelayedJob::ActiveJob::VERSION
  spec.authors = ["Alex"]
  spec.email = ["alex@tanda.co"]

  spec.summary = "Active Job adapter for Delayed Job"
  spec.homepage = "https://github.com/TandaHQ/delayed_job-active_job"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.1"

  spec.metadata = {
    "bug_tracker_uri" => "https://github.com/TandaHQ/delayed_job-active_job/issues",
    "changelog_uri" => "https://github.com/TandaHQ/delayed_job-active_job/releases",
    "source_code_uri" => "https://github.com/TandaHQ/delayed_job-active_job",
    "homepage_uri" => spec.homepage,
    "rubygems_mfa_required" => "true"
  }

  # Specify which files should be added to the gem when it is released.
  spec.files = Dir.glob(%w[LICENSE.txt README.md {exe,lib}/**/*]).reject { |f| File.directory?(f) }
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  # Runtime dependencies
  # spec.add_dependency "thor", "~> 1.2"
end
