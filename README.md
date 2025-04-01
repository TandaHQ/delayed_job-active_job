# delayed_job-active_job

[![Gem Version](https://img.shields.io/gem/v/delayed_job-active_job)](https://rubygems.org/gems/delayed_job-active_job)
[![Gem Downloads](https://img.shields.io/gem/dt/delayed_job-active_job)](https://www.ruby-toolbox.com/projects/delayed_job-active_job)
[![GitHub Workflow Status](https://img.shields.io/github/actions/workflow/status/TandaHQ/delayed_job-active_job/ci.yml)](https://github.com/TandaHQ/delayed_job-active_job/actions/workflows/ci.yml)

The Delayed Job adapter will be [removed from Rails soon](https://github.com/rails/rails/commit/d55ec9d5831b05ea5de75c105635c80376c0bf11). This gem extracts it so that you can continue using Delayed Job with Active Job.

If you are using a version of Rails that includes a Delayed Job adapter, using this gem will replace Rails' version with this gem's.

This gem implements some new features beyond what the Rails adapter did. See [features](#features) for instructions.

- Support for [`perform_all_later`](https://github.com/rails/rails/pull/46603).
- You can set `run_at` when bulk enqueueing.
- You can persist extra attributes on a job by writing to `job_attributes`.

---

- [Quick start](#quick-start)
- [Features](#features)
- [Support](#support)
- [License](#license)
- [Contribution guide](#contribution-guide)

## Quick start

```
gem install delayed_job-active_job
```

Configure the Active Job backend. [See the Rails docs for more information](https://guides.rubyonrails.org/active_job_basics.html#alternate-queuing-backends).

```ruby
# config/application.rb
config.active_job.queue_adapter = :delayed_job
```

## Features

This gem supports all the base functionality of any Active Job adapter. So anything in https://guides.rubyonrails.org/active_job_basics.html should work. If it doesn't please log an issue.

### `perform_all_later`

```ruby
ActiveJob.perform_all_later([HelloJob.new("Jamie"), HelloJob.new("John"), HelloJob.new("Alex")])
```

Under the hood, this uses `Delayed::Job.insert_all` to insert all the jobs into the database using a single SQL query.

### Set `run_at` when bulk enqueueing

```ruby
job = HelloJob.new("Alex")
job.run_at = 1.hour.from_now
ActiveJob.perform_all_later([job])
```

This is the equivalent to `HelloJob.set(wait: 1.hour).perform_later("Alex")`.

### Extra attributes via `job_attributes`

```ruby
job = HelloJob.new("Alex")
job.job_attributes = { metadata: "foo" }
job.enqueue
```

```ruby
job = HelloJob.new("Alex")
job.job_attributes = { metadata: "foo" }
ActiveJob.perform_all_later([job])
```

These examples would write `"foo"` into the `metadata` column on the `delayed_jobs` table. This works with any type of column, not just strings.

## Support

If you want to report a bug, or have ideas, feedback or questions about the gem, [let me know via GitHub issues](https://github.com/TandaHQ/delayed_job-active_job/issues/new) and I will do my best to provide a helpful answer. Happy hacking!

## License

The gem is available as open source under the terms of the [MIT License](LICENSE.txt).

## Contribution guide

Pull requests are welcome!
