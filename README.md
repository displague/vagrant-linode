Linode Vagrant Provider
==============================

`vagrant-linode` is a provider plugin for Vagrant that supports the
management of [Linode](https://www.linode.com/) linodes
(instances).

Current features include:
- create and destroy linodes
- power on and off linodes
- rebuild a linode
- provision a linode with the shell or other provisioners
- setup a SSH public key for authentication
- create a new user account during linode creation
- setup hostname during creation

The provider has been tested with Vagrant 1.6.3+ using Ubuntu 14.04 LTS and
Debian 7.5+ guest operating systems.

Install
-------
Installation of the provider couldn't be easier:

```bash
vagrant plugin install vagrant-linode
```

Configure
---------
Once the provider has been installed, you will need to configure your project
to use it. The most basic `Vagrantfile` to create a linode on Linode
is shown below:

```ruby
Vagrant.configure('2') do |config|

  config.vm.provider :linode do |provider, override|
    override.ssh.private_key_path = '~/.ssh/id_rsa'
    override.vm.box = 'linode'
    override.vm.box_url = "https://github.com/displague/vagrant-linode/raw/master/box/linode.box"

    provider.api_key = 'API_KEY'
    provider.distribution = 'Ubuntu 14.04 LTS'
    provider.datacenter = 'newark'
    provider.plan = 'Linode 1024'
    # provider.planid = <int>
    # provider.paymentterm = <*1*,12,24>
    # provider.datacenterid = <int>
    # provider.image = <string>
    # provider.image_id = <int>
    # provider.kernel = <string>
    # provider.kernelid = <int>
    # provider.private_networking = <boolean>
    # provider.stackscript = <string>
    # provider.stackscriptid = <int>
    # provider.distributionid = <int>
  end
end
```

Please note the following:
- You *must* specify the `override.ssh.private_key_path` to enable authentication
  with the linode. The provider will create a new Linode SSH key using
  your public key which is assumed to be the `private_key_path` with a *.pub*
  extension.
- You *must* specify your Linode Personal Access Token. This may be
  found on the control panel within the *my profile* &gt; *API Keys* section.

**Supported Configuration Attributes**

The following attributes are available to further configure the provider:
- `provider.distribution` - A string representing the distribution to use when
   creating a new linode (e.g. `Debian 8.1`). The available options may
   be found on [Linode's Supported Distributions](https://www.linode.com/distributions) page.
   It defaults to `Ubuntu 14.04 LTS`.
- `provider.datacenter` - A string representing the datacenter to create the new
   linode in. It defaults to `dallas`.
- `provider.plan` - A string representing the size to use when creating a
  new linode (e.g. `Linode 2048`). It defaults to `Linode 1024`.
- `provider.private_networking` - A boolean flag indicating whether to enable
  a private network interface. It defaults to `false`.
- `provider.ssh_key_name` - A string representing the name to use when creating
  a Linode SSH key for linode authentication. It defaults to `Vagrant`.
- `provider.setup` - A boolean flag indicating whether to setup a new user
  account and modify sudo to disable tty requirement. It defaults to `true`.
  If you are using a tool like [packer](https://packer.io) to create
  reusable snapshots with user accounts already provisioned, set to `false`.
- `provider.label` - A string representing the Linode label to assign when
  creating a new linode
- `provider.group` - A string representing the Linode's Display group to assign
  when creating a new linode

The provider will create a new user account with the specified SSH key for
authorization if `config.ssh.username` is set and the `provider.setup`
attribute is `true`.

### provider.plan

Each Linode Tier has been assigned a Plan Identifcation Number.
Current Plan-ID table follows:

| PlanID  | Plan                      |
|:------- |:------------------------- |
|    1    |  1GB Plan (Linode 1024)   |
|    2    |  2GB Plan (Linode 2048)   |
|    4    |  4GB Plan (Linode 4096)   |
|    6    |  8GB Plan (Linode 8192)   |
|    7    | 16GB Plan (Linode 16384)  |
|    8    | 32GB Plan (Linode 32768)  |
|    9    | 48GB Plan (Linode 49152)  |
|   10    | 64GB Plan (Linode 65536)  |
|   12    | 96GB Plan (Linode 98304)  |

This can be obtained through vagrant with:
```
vagrant linode datacenters
```

Or using curl:
```
curl -X POST "https://api.linode.com/?api_action=avail.plans" \
     --data-ascii api_key="$LINODE_API_KEY" \
     2>/dev/null | jq '.DATA [] | .PLANID,.LABEL'
```

More detail: [Linode API - Plans](https://www.linode.com/api/utility/avail.plans)

### provider.datacenter

Each region has been specified with a Data Center ID.
Current Region-ID table is:

| DatacenterID | Datacenter | Location            |
|:-------      |:------     |:--------------------|
|   4          | atlanta    | Atlanta, GA, USA    |
|   2          | dallas     | Dallas, TX, USA     |
|   3          | fremont    | Fremont, CA, USA    |
|   7          | london     | London, England, UK |
|   6          | newark     | Newark, NJ, USA     |
|   8          | tokyo      | Tokyo, JP           |
|   9          | singapore  | Singapore, SGP      |

You can find latest datacenter ID number using Vagrant subcommands:

```
vagrant linode datacenters
```

Or directly through the API:


```
curl -X POST "https://api.linode.com/?api_action=avail.datacenters" \
     --data-ascii api_key="$LINODE_API_KEY" \
     2>/dev/null | jq '.DATA [] | .DATACENTERID,.ABBR,.LOCATION'
```

More detail: [Linode API - Datacenters](https://www.linode.com/api/utility/avail.datacenters)

### provider.kernel

The kernel can be specified using the *kernelid* provider parameter, or with *kernel* which
will use a partial text match.

```
curl -X POST "https://api.linode.com/?api_action=avail.kernels" \
     --data-ascii api_key="$LINODE_API_KEY" \
     2>/dev/null | jq '.DATA [] | .KERNELID,.LABEL'
```

More detail: [Linode API - Kernels](https://www.linode.com/api/utility/avail.kernels)


Run
---
After creating your project's `Vagrantfile` with the required configuration
attributes described above, you may create a new linode with the following
command:

    $ vagrant up --provider=linode

This command will create a new linode, setup your SSH key for authentication,
create a new user account, and run the provisioners you have configured.

The  environment variable `VAGRANT_DEFAULT_PROVIDER` can be set to `linode` to avoid sending `--provider=linode` on each `vagrant up`. 

**Supported Commands**

The provider supports the following Vagrant sub-commands:
- `vagrant destroy` - Destroys the linode instance.
- `vagrant ssh` - Logs into the linode instance using the configured user
  account.
- `vagrant halt` - Powers off the linode instance.
- `vagrant provision` - Runs the configured provisioners and rsyncs any
  specified `config.vm.synced_folder`. (see https://docs.vagrantup.com/v2/synced-folders/rsync.html)
- `vagrant reload` - Reboots the linode instance.
- `vagrant rebuild` - Destroys the linode instance and recreates it with the
  same IP address which was previously assigned.
- `vagrant status` - Outputs the status (active, off, not created) for the
  linode instance.
- `vagrant linode` - Offers Linode resource listing options for datacenters,
  distributions, images, networks, plans, and servers


More Docs and Tools
-------------------
[Linode Guides and Tutorials - Using Vagrant to Manage Linode Environments](https://linode.com/docs/applications/configuration-management/vagrant-linode-environments)
[Puphpet - Online Vagrantfile Generator](https://puphpet.com/#vagrantfile-linode)

Contribute
----------
To contribute, clone the repository, and use [Bundler](http://gembundler.com)
to install dependencies:

    $ bundle

To run the provider's tests:

    $ bundle exec rake test

You can now make modifications. Running `vagrant` within the Bundler
environment will ensure that plugins installed in your Vagrant
environment are not loaded.

[![Join the chat at https://gitter.im/displague/vagrant-linode](https://badges.gitter.im/Join%20Chat.svg)](https://gitter.im/displague/vagrant-linode?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge)
[![Code Climate](https://codeclimate.com/github/displague/vagrant-linode/badges/gpa.svg)](https://codeclimate.com/github/displague/vagrant-linode)
[![Test Coverage](https://codeclimate.com/github/displague/vagrant-linode/badges/coverage.svg)](https://codeclimate.com/github/displague/vagrant-linode)
[![Gem Version](https://badge.fury.io/rb/vagrant-linode.svg)](http://badge.fury.io/rb/vagrant-linode)
[![Dependency Status](https://gemnasium.com/displague/vagrant-linode.svg)](https://gemnasium.com/displague/vagrant-linode)
[![MIT Licensed](https://img.shields.io/badge/license-MIT-green.svg)](https://tldrlegal.com/license/mit-license)

