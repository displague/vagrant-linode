# Changelog

## v0.4.1

* fixes handling of old plan labels [#88](https://github.com/displague/vagrant-linode/issues/88)
* adds a custom User-Agent token to support usage analytics

## v0.4.0

* added support for Linode Volumes
* added `vagrant linode volumes list` command

## v0.3.0

* fixes for Vagrant 2.0.1 (now requires Ruby 2.2.0+)
* xen-only kernels are no longer available (Fixes KVM Grub options)
* rebuild command warns / quits if Linode is not powered down

## v0.2.8

* fixes for Vagrant 1.9

## v0.2.7

* Update default plan (and ways to set it) and default distro

## v0.2.6

* added StackScript support

## v0.2.5

* destroy works when linode is already deleted

## v0.2.4

* fixed the box image

## v0.2.3

* fixed rsync before provision on startup

## v0.2.2

* fixed provision on startup
