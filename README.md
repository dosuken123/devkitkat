# Michi

Michi is a framework for development kits. It lets you
bootstrap separate services for running a complex application easily.
This is especially helpful for local development that runs/compiles everything from source code.

## Features

This tool provides the following features:

- Easy configuration, easiser than docker-compose.
- Customizable/Flexible scripts for controlling services.
- Logging command output dy default.
- Respect the best practice architecture of Cloud Native.
- Easy to run services in containers (Not available yet).
- Distrubte machine resources to the cloud VM (Not available yet).

## The only config file - `.michi.yml`

The only config file `.michi.yml` has to be placed at the root directory where you want to
download/prepare services. These are available keys.

|Key                                         |Type        |Required|Default|Description|
|---                                         |---         |---     |---|---|
|`application:`                              |String      |Yes     |-|The name of the application that consists of the services|
|`environment:type:`                         |String      |Yes     |-|The type of the environment. One of `local`, `docker` or `cloud`. Default is `local`.|
|`environment:image:`                        |String      |Yes     |-|The docker image. Only effective when `type` is `docker` or `cloud`|
|`services:`                                 |Hash        |Yes     |-|The services to run the application|
|`services:<name>`                           |Hash        |Yes     |-|The service name e.g. `rails`, `db`, `redis`|
|`services:<name>:repo: <value>`             |String      |No      |-|The git URL of the repository|
|`services:<name>:<key>: <value>`            |Hash        |No      |-|The key and value of the environment variable. e.g. `POSTGRES_PASSWORD: abcdef`. |
|`groups:`                                   |Hash        |No      |-|The groups of the services|
|`groups:<name>: <service-names>`            |Hash        |No      |-|The name of the group and the service names|

There are pre-occupied special keys, please do not use these keys in your config file: `services:system`, `services:self`

## Sample `.michi.yml`

```yaml
application: awesome-app

environment:
  type: local

services:
  web:
    repo: https://gitlab.com/gitlab-org/gitlab-ce.git
    port: 1234
  db:
    port: 9999
```

## Michi image

When you run your application with docker containers, you might need to write up
[Dockerfile](https://docs.docker.com/engine/reference/builder/) and build the image at first,
this often is time consuming and repeatable task.
To avoid this cumbersome step, michi provides some useful pre-built machines, which
works with your application on the fly.
These images are defined in michi as a ruby script and easy to customize/extend.
If you don't find useful machines, you can still define it in `services/<name>/dockerfile` directory,
however, please consider contributing to this repository for the other people who
would be stuck into the same pitfall/situation.

- `Michi::Environment::Image::CommonRubyOnRails`
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

You can add a script with the following command `michi add-script --name=<name> <target>`.
It creates a script file at `services/<name>/script/<name>`, and you
have to code the script details.

As the best practice, you should initialize a script dir at first, to do so, execute
`michi add-script --basic <target>`. It adds the following basic scripts that you'd need

- configure/unconfigure ... Configure/Unconfigure the service (Typically, initializes the config file, etc)
- start/stop ... Start/Stop the service

So you might want to execute `michi add-script --basic all` after you've prepared
.michi.yml. After you write up the commands, you can execute scripts with a command
like `michi rails configutre` or `michi php start`.

You can also define system scripts that does not belong to a specific service.
There is a handy command `michi add-script <name> system` and it adds a script to `services/system/script` dir.
. For the system script execution, you can ommit `<target>` from
the command line e.g. `michi add-test-domain` will work instead of `michi add-test-domain system`. 
As always, log files are stored in `services/system/log` (See more [Service structure](#service-structure))

## Predefined scripts

Michi provides predefined scripts that are useful in common development scenarios.

|Script name    |Available options        |Description|
|---            |---                      |---|
|`clone`        |`GIT_DEPTH` ... Speicify git-depth|Clone source code from the `services:<name>:repo:`|
|`pull`         |`GIT_DEPTH` ... Speicify git-depth|Pull source code from the `services:<name>:repo:`|
|`download`     |N/A                      |Download source code from the `services:<name>:repo:`|
|`clean`        |N/A                      |Remove all files from `data`, `cache`, `log` and `src` dirs|
|`docker-build` |`TAG`                    |Build a docker image|
|`docker-push`  |`REGISTRY`               |Push a docker image|
|`add-user`     |`TAG`                    |Add a user to the current system (It's useful for containerized images)|
|`add-script`   |`--basic`                |Add a script to services|
|`poop`         |N/A                      |:poop:|

## Predefined group names

- `all` ... All defined services in `.michi.yml`

## Predefined variables

Michi inject these predefined variables into the scripts by default.

- `MI_<service>_DIR` ... The root directory path of the service.
- `MI_<service>_SCRIPT_DIR` ... The script directory path of the service.
- `MI_<service>_SRC_DIR` ... The source directory path of the service.
- `MI_<service>_CACHE_DIR` ... The cache directory path of the service.
- `MI_<service>_DATA_DIR` ... The data directory path of the service.
- `MI_<service>_LOG_DIR` ... The log directory path of the service.
- `MI_<service>_EXAMPLE_DIR` ... The example directory path of the service.
- `MI_<service>_<key>` ... The value of the user-defined variable.

NOTE:
 - User-defined variables are injected with the bare name. e.g. If you define
   `VERSION: 1`, then you get the value with `echo $VERSION`. From the other services,
   the variable can be fetched as `MI_<service>_<key>`.
 - `service` is the *uppercase* service *name*. e.g. if the service name is
  `rails`, `MI_RAILS_DIR` is the root directory path of the service.
 - `key` is *uppercase* e.g. `MI_RAILS_HOST`
 - You can also use `SELF` instead of specifying a service name.
   The `SELF` indicates that it's a context specific parameter, for example,
   if you run a script for `workhorse` service, `MI_SELF_DIR` is `services/workhorse`,
   on the other hand, if you run a script for `gitaly` service, `MI_SELF_DIR` is `services/gitaly`.

## How to control services via scripts

Basically, command execution follows the below convention.

`michi <script-name> <target - service name or group name>`

For example, if you want to start `rails` service, your command would look like

`michi start rails`

, Or, if you want to start all services belong to the `backend` group,

`michi start backend`

, Or, if you want to pass multiple services, use comma separated service names,

`michi start rails,postgres,redis`

, Or, if you want to exclude a specific service from a group, use `--exclude` option,

`michi start backend --exclude redis`

## Sample commands

```
michi pull default                          # Pull source code for the default group
michi configure default                     # It configures source code for the default group
michi start postgresql,redis,gitaly         # It starts `postgresql`, `redis` and `gitaly` services.
michi seed rails                            # It Seeds for `rails` service
michi start default                         # It starts services of the `default` group
```

## Options for `michi`

- `--path /path/to/the` ... The root directory that contains `.michi.yml` and manage the service dirs.
- `--variables KEY=VAR` ... The additional environment variables for services.
- `--exclude <name>` ... The excluded service from the group.

Example:

`michi start rails --path $HOME/awesome-app-dev-kit/ --variables AWS_CRED=XXXXX`

## Installation

    $ gem install michi

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitLab at https://gitlab.com/dosuken123/michi. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Michi project’s codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/[USERNAME]/michi/blob/master/CODE_OF_CONDUCT.md).
