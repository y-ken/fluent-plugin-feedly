# fluent-plugin-feedly

## Overview

Fluentd input plugin to fetch RSS/ATOM feed via Feedly Could.

## Dependencies

* Ruby 1.9.3+
* Fluentd 0.10.54+

## Installation

install with gem or fluent-gem command as:

`````
# for system installed fluentd
$ gem install fluent-plugin-feedly

# for td-agent
$ sudo /usr/lib64/fluent/ruby/bin/fluent-gem install fluent-plugin-feedly
`````

## Configuration

`````
<source>
  type             feedly

  # Set feedly access token
  # ref. https://feedly.com/v3/auth/dev
  access_token     ACCESS_TOKEN    # Required

  # Set file-path to store last fetched article position
  state_file       /var/log/td-agent/feedly.state  # Required

  # Set output tag
  tag              input.feedly    # Required
  
  # List subscribe categories in your feedly account with JSON Array
  subscribe_categories  ["global.all"]  # Optional (default: global.all)

  # Set update checking frequency
  run_interval     30m             # Optional (default: 10m)

  # Set bulk read size
  fetch_count      20              # Optional (default: 20)
  
  # fetching range of time within 30d
  fetch_time_range 3d              # Optional (default: 3d)
  
  # fetching range of time for initial startup within 30d
  fetch_time_range_on_startup 2w   # Optional (default: 2w)

  # Using sandbox account
  enable_sandbox   false           # Optional (default: false)
  
  # Set log level for this plugin. To see debug level, set 'debug' for this value.
  # it can see at stdout as like `$ tail -f /var/log/td-agent/td-agent.log`
  log_level        info 　　　　　　 # Optional (default: info)
</source>
`````

**note** : The `subscribe_categories` is also supported with single or multi line configuration like below.

```
# single line
subscribe_categories ["先端技術", "mysql"]

# multi line
subscribe_categories [
  "先端技術",
  "mysql"
]
```

## Usage

After installed this plugin, executing fluentd with following configuration.

```
$ cat /etc/td-agent/td-agent.conf
<source>
  type             feedly
  access_token     YOUR_ACCESS_TOKEN
  state_file       /var/log/td-agent/feedly.state
  tag              input.feedly
  run_interval     30m
  fetch_time_range 1h
  fetch_time_range_on_startup 3h
  log_level        debug
</source>

<match input.feedly>
  type             file
  path             /tmp/feedly*.json
  symlink_path     /tmp/feedly.json
  format           json
  append           true
</match>
```

You can see the behavior about this plugin with this command.

```
# to check stdout of this plugin
$ tail -f /var/log/td-agent/td-agent.log
2014-10-16 14:47:01 +0900 [debug]: Feedly: fetched articles. articles=416 request_option={:count=>1000, :continuation=>"148cfb7f516:9371a3c:726280cf", :newerThan=>1412228787000}
2014-10-16 15:02:02 +0900 [debug]: Feedly: fetched articles. articles=492 request_option={:count=>1000, :continuation=>nil, :newerThan=>1413428521000}
```

```
# to check fetched articles
$ tail -f /tmp/feedly.json | jq "."
```

## TODO

Pull requests are very welcome!!

## Copyright

Copyright © 2014- Kentaro Yoshida ([@yoshi_ken](https://twitter.com/yoshi_ken))

## License

Apache License, Version 2.0

## Contributing

1. Fork it ( https://github.com/[my-github-username]/fluent-plugin-feedly/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
