# delayed_job-active_job

[![Gem Version](https://img.shields.io/gem/v/delayed_job-active_job)](https://rubygems.org/gems/delayed_job-active_job)
[![Gem Downloads](https://img.shields.io/gem/dt/delayed_job-active_job)](https://www.ruby-toolbox.com/projects/delayed_job-active_job)
[![GitHub Workflow Status](https://img.shields.io/github/actions/workflow/status/TandaHQ/delayed_job-active_job/ci.yml)](https://github.com/TandaHQ/delayed_job-active_job/actions/workflows/ci.yml)
[![Code Climate maintainability](https://img.shields.io/codeclimate/maintainability/TandaHQ/delayed_job-active_job)](https://codeclimate.com/github/TandaHQ/delayed_job-active_job)

The Delayed Job adapter will be [removed from Rails soon](https://github.com/rails/rails/commit/d55ec9d5831b05ea5de75c105635c80376c0bf11). This gem extracts it so that you can continue using Delayed Job with Active Job.

It also implements some new features the Rails adapter didn't support:

- Support for [`perform_all_later`](https://github.com/rails/rails/pull/46603).
- You can set `run_at` directly on a job instance.
- You can persist extra attributes on a job by writing to `job_attributes`.

---

- [Quick start](#quick-start)
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

## Support

If you want to report a bug, or have ideas, feedback or questions about the gem, [let me know via GitHub issues](https://github.com/TandaHQ/delayed_job-active_job/issues/new) and I will do my best to provide a helpful answer. Happy hacking!

## License

The gem is available as open source under the terms of the [MIT License](LICENSE.txt).

## Contribution guide

Pull requests are welcome!
