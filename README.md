# cron.cr

Not safe. Not efficient. Probably shouldn't be used.

Modifies cron tabs.


## Installation

Add this to your application's `shard.yml`:

```yaml
dependencies:
  cron:
    github: chris-huxtable/cron.cr
```


## Usage

```crystal
require "cron"
```

Example:
```crystal
tab = Cron.tab()

tab.add_task("tag.for.task", Cron::Task.reboot("some sh command"))
tab.replace_task("tag.for.task", Cron::Task.task("some sh command", 0, 1))
tab.remove_task("tag.for.task")

tab.disable_task("tag.for.task")
tab.enable_task("tag.for.task")
```


## Contributing

1. Fork it ( https://github.com/chris-huxtable/cron.cr/fork )
2. Create your feature branch (git checkout -b my-new-feature)
3. Commit your changes (git commit -am 'Add some feature')
4. Push to the branch (git push origin my-new-feature)
5. Create a new Pull Request


## Contributors

- [Chris Huxtable](https://github.com/chris-huxtable) - creator, maintainer
