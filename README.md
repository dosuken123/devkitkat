[![pipeline status](https://gitlab.com/dosuken123/devkitkat/badges/master/pipeline.svg)](https://gitlab.com/dosuken123/devkitkat/commits/master)
[![Gem Version](https://badge.fury.io/rb/devkitkat.svg)](https://badge.fury.io/rb/devkitkat)

# Devkitkat

Devkitkat is a framework for development kits. It lets you
bootstrap separate services for running a complex application easily.
This is especially helpful for local development that runs/compiles everything from source code.

## Key concepts

- It's an alternative solution of docker-compose.
- It's an alternative solution of Makefile.
- Convention over configuration. No need to write up complicated config file from scratch.
- Prepare one image to work on everything (All you need is runnable VM not
  fully fine-tuned containers/images for deployments)
- Respect the best practice architecture of Cloud Native.
- No more Makefile for bootstraping.

## Features

This tool provides the following features:

- Maintain your services in clean and explicit architecture.
- Control services with an easy and intuitive command.
- Fully customizable scripts.
- Logging everything by default.
- Easy to run services in containers.
- Distrubte machine resources to the cloud VM (Not available yet).

## The only config file - `.devkitkat.yml`

The only config file `.devkitkat.yml` has to be placed at the root directory where you want to
download/prepare services. These are available keys.

|Key                                         |Type        |Required|Default|Description|
|---                                         |---         |---     |---|---|
|`services:`                                 |Hash        |Yes     |-|The services to run the application|
|`services:<name>`                           |Hash        |Yes     |-|The service name e.g. `rails`, `db`, `redis`|
|`services:<name>:repo: <value>`             |String      |No      |-|The git URL of the repository|
|`services:<name>:<key>: <value>`            |Hash        |No      |-|The key and value of the environment variable. e.g. `POSTGRES_PASSWORD: abcdef`. |
|`image:`                                    |String      |No      |-|The docker image. Only effective when `type` is `docker` or `cloud`|
|`groups:`                                   |Hash        |No      |-|The groups of the services|
|`groups:<name>: <service-names>`            |Hash        |No      |-|The name of the group and the service names|
|`application:`                              |String      |No      |-|The name of the application that consists of the services|

There are pre-occupied special keys, please do not use these keys in your config file: `services:system`, `services:self`

### `machine:` key

|Key                                         |Type        |Required|Default|Description|
|---                                         |---         |---     |---|---|
|`machine:`                                  |Hash        |No      |-|The machine to run the application|
|`machine:driver`                            |String      |No      |-|The driver name, one of `none` or `docker`. Default is `none`.|
|`machine:location`                          |String      |No      |-|The machine location, one of `local` or `remote`. Default is `local`.|
|`machine:image`                             |String      |No      |-|The docker image used as the machine image.|
|`machine:extra_hosts`                       |Array<String>|No      |-|Extra hosts to be added to `/etc/hosts` in the machine|
|`machine:network_mode`                      |String      |No      |-|Docker Network Mode, one of `bridge`, `host`.|
|`machine:extra_write_accesses`              |Array<String>|No      |-|Extra write access to each service. By default, a service mounts only own directory as read-write and mounts the other service directories as read-only volume. To add extra write access, you specify `'<service-name>:to:<service-name>'`|



## Sample `.devkitkat.yml` that runs services in local environment

```yaml
services:
  web:
    repo: https://gitlab.com/gitlab-org/gitlab-ce.git
    port: 1234
  db:
    port: 9999
```

## Sample `.devkitkat.yml` that runs services in docker containers

```yaml
machine:
  driver: docker
  image: your-dev-machine-image:latest

services:
  web:
    repo: https://gitlab.com/gitlab-org/gitlab-ce.git
    port: 1234
  db:
    port: 9999
```

## Devkitkat image

The key concept is to prepare only one docker image to run services. It's just a
virtual machine just like your local computer. You install native applications/runtime
(such as postgresql) on your computer. We just need one workable image. So each
service has an individual container which initialized from the single image.

When you run your application with docker containers, you might need to write up
[Dockerfile](https://docs.docker.com/engine/reference/builder/) and build the image at first,
this often is time consuming and repeatable task.
To avoid this cumbersome step, devkitkat provides some useful pre-built machines, which
works with your application on the fly.
These images are defined in devkitkat as a ruby script and easy to customize/extend.
If you don't find useful machines, you can still define it in `services/<name>/dockerfile` directory,
however, please consider contributing to this repository for the other people who
would be stuck into the same pitfall/situation.

- `Devkitkat::Environment::Image::CommonRubyOnRails`
  - `author`
  - `homepage`
  - etc

## Service structure

Each service is stored in the following directories:

|Path                               |Description|
|---                                |---|
|`services/<name>/src/`| The directory for source code of the service |
|`services/<name>/script/`| The directory for scripts that controls the service e.g. start, stop, etc.|
|`services/<name>/data/`| The directory for storing permanent data e.g. database.|
|`services/<name>/cache/`| The directory for storing ephemeral data to optimize service boot.|
|`services/<name>/log/`| The directory for logged console output.|
|`services/<name>/example/`| The directory for extra example scripts that shouldn't be managed in the source repository. |
|`services/<name>/dockerfile/`| The directory for the docker file that builds the image for the service|

## How to write scripts

Since your service's startup command could vary per your application preference,
you have to define start/stop/configure/etc scripts manually.

You can add a script with the following command `devkitkat add-script --name=<name> <target>`.
It creates a script file at `services/<name>/script/<name>`, and you
have to code the script details.

As the best practice, you should initialize a script dir at first, to do so, execute
`devkitkat add-script --basic <target>`. It adds the following basic scripts that you'd need

- configure/unconfigure ... Configure/Unconfigure the service (Typically, initializes the config file, etc)
- start/stop ... Start/Stop the service

So you might want to execute `devkitkat add-script --basic all` after you've prepared
.devkitkat.yml. After you write up the commands, you can execute scripts with a command
like `devkitkat rails configutre` or `devkitkat php start`.

You can also define system scripts that does not belong to a specific service.
There is a handy command `devkitkat add-script <name> system` and it adds a script to `services/system/script` dir.
. For the system script execution, you can ommit `<target>` from
the command line e.g. `devkitkat add-test-domain` will work instead of `devkitkat add-test-domain system`. 
As always, log files are stored in `services/system/log` (See more [Service structure](#service-structure))

### Shared script

You can create a shared script to be included in service scripts. To do so,
execute:

```
devkitkat add-shared-script
```

This adds `shared` script under `services/system` directory. You can define a
shared function in the script.

To include the shared script, you need to update your service script as the following:

```shell
#!/bin/bash
source ${DK_SYSTEM_SCRIPT_SHARED_DIR}

# Call a function defiend in the `shared` script
```

## Utility commands, Predefined scripts and Options

Devkitkat provides predefined scripts that are useful in common development scenarios.

```
Usage: devkitkat <command/script> <target> [args] [options]

Options:
    -p, --path PATH                  The root path of the .devkitkat.yml
        --exclude SERVICE            Exclude serviced from the specified target
    -e, --env-var VARIABLE           additional environment variables
    -d, --debug                      Debug mode
    -i, --interactive                Interactive mode. STDOUT is streamed in console.
    -v, --version                    Show version
    -h, --help                       Show help

Utility Commands:
add-script          - Add a script file
add-example         - Add an example file
add-shared-script   - Add s shared script
help                - Show help

Predefined scripts:
clone               - Clone repository (Available options: `GIT_DEPTH`)
pull                - Pull latest source code
clean               - Clean the service dir
poop                - Poop
```

Example:

`devkitkat start rails --path $HOME/awesome-app-dev-kit/ --env-var AWS_CRED=XXXXX`

## Predefined group names

- `all` ... All defined services in `.devkitkat.yml`

## Predefined variables

Devkitkat inject these predefined variables into the scripts by default.

- `DK_<service>_DIR` ... The root directory path of the service.
- `DK_<service>_SCRIPT_DIR` ... The script directory path of the service.
- `DK_<service>_SRC_DIR` ... The source directory path of the service.
- `DK_<service>_CACHE_DIR` ... The cache directory path of the service.
- `DK_<service>_DATA_DIR` ... The data directory path of the service.
- `DK_<service>_LOG_DIR` ... The log directory path of the service.
- `DK_<service>_EXAMPLE_DIR` ... The example directory path of the service.
- `DK_<service>_<key>` ... The value of the user-defined variable.

NOTE:
 - User-defined variables are injected with the bare name. e.g. If you define
   `VERSION: 1`, then you get the value with `echo $VERSION`. From the other services,
   the variable can be fetched as `DK_<service>_<key>`.
 - `service` is the *uppercase* service *name*. e.g. if the service name is
  `rails`, `DK_RAILS_DIR` is the root directory path of the service.
 - `key` is *uppercase* e.g. `DK_RAILS_HOST`
 - You can also use `SELF` instead of specifying a service name.
   The `SELF` indicates that it's a context specific parameter, for example,
   if you run a script for `workhorse` service, `DK_SELF_DIR` is `services/workhorse`,
   on the other hand, if you run a script for `gitaly` service, `DK_SELF_DIR` is `services/gitaly`.

## How to control services via scripts

Basically, command execution follows the below convention.

`devkitkat <script-name> <target - service name or group name>`

For example, if you want to start `rails` service, your command would look like

`devkitkat start rails`

, Or, if you want to start all services belong to the `backend` group,

`devkitkat start backend`

, Or, if you want to pass multiple services, use comma separated service names,

`devkitkat start rails,postgres,redis`

, Or, if you want to exclude a specific service from a group, use `--exclude` option,

`devkitkat start backend --exclude redis`

## Workflow example

```
devkitkat pull default                          # Pull source code for the default group
devkitkat configure default                     # It configures source code for the default group
devkitkat start postgresql,redis,gitaly         # It starts `postgresql`, `redis` and `gitaly` services.
devkitkat seed rails                            # It Seeds for `rails` service
devkitkat start default                         # It starts services of the `default` group
```

## Supported docker version

Docker 19.03.4+

## Installation

    $ gem install devkitkat

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

### Tips

**Execute only fast tests**

`bundle exec rspec -t ~slow`

**Execute only slow tests**

`bundle exec rspec -t slow`

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/dosuken123/devkitkat. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Devkitkat project’s codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/[USERNAME]/devkitkat/blob/master/CODE_OF_CONDUCT.md).

## How to release a new version

1. Update `Devkitkat::VERSION`
1. Execute `bin/release`
