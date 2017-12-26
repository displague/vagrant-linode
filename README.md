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
is shown below (with most of the available options included but commented out):

```ruby
Vagrant.configure('2') do |config|

  config.vm.provider :linode do |provider, override|
    override.ssh.private_key_path = '~/.ssh/id_rsa'
    override.vm.box = 'linode/ubuntu1404'

    provider.api_key = 'API_KEY'
    provider.distribution = 'Ubuntu 16.04 LTS'
    provider.datacenter = 'newark'
    provider.plan = 'Linode 2048'
    # provider.planid = <int>
    # provider.paymentterm = <*1*,12,24>
    # provider.datacenterid = <int>
    # provider.image = <string>
    # provider.imageid = <int>
    # provider.kernel = <string>
    # provider.kernelid = <int>
    # provider.private_networking = <boolean>
    # provider.stackscript = <string> # Not Supported Yet
    # provider.stackscriptid = <int> # Not Supported Yet
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
  new linode (e.g. `Linode 4096`). It defaults to `Linode 2048`.
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
Current (Feb 2017) Plan-ID table follows:

| PlanID  | Plan                          |
|:------- |:----------------------------- |
|    1    |   1GB Standard (Linode 1024)  |
|    2    |   2GB Standard (Linode 2048)  |
|    3    |   4GB Standard (Linode 4096)  |
|    4    |   8GB Standard (Linode 8192)  |
|    5    |  12GB Standard (Linode 12288) |
|    6    |  24GB Standard (Linode 24576) |
|    7    |  48GB Standard (Linode 49152) |
|    8    |  64GB Standard (Linode 65536) |
|    9    |  80GB Standard (Linode 81920) |
|   10    |  16GB HighMem (Linode 16384)  |
|   11    |  32GB HighMem (Linode 32768)  |
|   12    |  60GB HighMem (Linode 61440)  |
|   13    | 100GB HighMem (Linode 102400) |
|   14    | 200GB HighMem (Linode 204800) |

This can be obtained through vagrant with:
```
vagrant linode plans <machine_name>
```

Or using curl:
```
curl -X POST "https://api.linode.com/?api_action=avail.linodeplans" \
     --data-ascii api_key="$LINODE_API_KEY" \
     2>/dev/null | jq '.DATA [] | .PLANID,.LABEL'
```

More detail: [Linode API - Plans](https://www.linode.com/api/utility/avail.linodeplans)

### provider.datacenter

Each region has been specified with a Data Center ID.
Current (Feb 2017) Datacenter-ID table is:

| DatacenterID | Datacenter | Location            |
|:-------      |:------     |:--------------------|
|   4          | atlanta    | Atlanta, GA, USA    |
|   2          | dallas     | Dallas, TX, USA     |
|   3          | fremont    | Fremont, CA, USA    |
|   7          | london     | London, England, UK |
|   6          | newark     | Newark, NJ, USA     |
|   8          | tokyo      | Tokyo, JP           |
|   9          | singapore  | Singapore, SGP      |
|   10         | frankfurt  | Frankfurt, DE       |
|   11         | shinagawa1 | Tokyo 2, JP         |

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

### provider.volumes - [Volume Handling](https://www.linode.com/docs/platform/how-to-use-block-storage-with-your-linode/)

The plugin can create and attach additional volumes when creating Linodes. `vagrant rebuild` calls will rebuild the VM only and reattach the volume afterwards without losing the contents.

```rb
config.vm.provider :linode do |linode|
  linode.plan = "Linode 2048"
  linode.volumes = [
    {label: "extra_volume", size: 1},
  ]
end
```

NOTES:
* The volume needs to be formatted and mounted inside the VM either manually or by a StackScript, etc.
* The plugin doesn't do any volume metadata management. If a volume is renamed the next `vagrant up` call will create a new one.
* Running `vagrant destroy` will **NOT** destroy the volumes.

### nfs.functional

The sync provider, NFS, has been disabled to make rsync easier to use.  To enable NFS,
run Vagrant with an environment variable `LINODE_NFS_FUNCTIONAL=1`.  This will require
a bit more configuration between the Linode and the Vagrant host.

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

To run the provider's tests, first install vagrant [as shown here](https://www.vagrantup.com/downloads.html) and then use rake:

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

