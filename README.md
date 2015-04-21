# OpenProject Docker Development


A Dockerfile and docker-compose script that builds a development container of OpenProject alongside a PostgreSQL 9.4.X server.

✓ Employs docker-compose to separate OpenProject and PostgreSQL / Data container.

✓ Database setup as a linked container.

✓ Robust image sources, using [offical ruby](https://registry.hub.docker.com/_/ruby/) and [postgres](https://registry.hub.docker.com/_/postgres/) images.

✓ Data containers for bundler and Postgres data directories.

## Prerequisites

On your host machine, you need Docker. [See their installation guides for more details](https://docs.docker.com/installation/#installation).


### Mac OS X

With the Linux kernel, Docker can run containers directly on the host. These kernel features aren't natively available on an OS X host machine, thus a virtual machine is used as a proxy to run the docker daemon itself.

A popular choice is [boot2docker](http://boot2docker.io/), which runs a Tiny Core Linux using VirtualBox as the virtualization engine.
However, [a reported problem](https://github.com/boot2docker/boot2docker/issues/64) for boot2docker is the default file synchronization with VirtualBox shared folders (vboxfs), which is *painfully* slow and is unsuited for a development environment.

A number of workarounds exist:


1. [Patching the boot2docker VM](http://syskall.com/using-boot2docker-using-nfs-instead-of-vboxsf/) to add NFS support. This requires manually adding the boot2docker vm to the Mac's NFS export configuration.
2. Employing [a custom boot2docker box with Vagrant](https://github.com/blinkreaction/boot2docker-vagrant), which allows a selection of faster mechanisms (automatic NFS configuration, rsync).
3. A data container with a synchronization engine (e.g., https://github.com/leighmcculloch/docker-unison). This looks promising and may be a viable alternative to Vagrant.
4. A host-side script to automate unison / fswatch synchronization such as [Hodor](https://github.com/gansbrest/hodor). However, with it

For the time being, this repo includes the second workaround with Vagrant. Feel free to use a different method on Mac.

To install the custom boot2docker vm, you'll need Virtualbox and Vagrant. I assume you have installed and actively use [Homebrew](http://brew.sh/).

With brew-cask (http://caskroom.io/), you can install images from the commandline. If you do not have brew cask installed, install with the following command.

    brew install caskroom/cask/brew-cask

Then, install the dependencies:
	
	brew cask install vagrant
	brew cask install virtualbox

And then install [docker and docker-compose](https://docs.docker.com/compose/install/).

	brew install docker docker-compose
	
	
You can then control the vagrant VM similar to boot2docker, using `vagrant up` and `vagrant halt`.
[See the vagrant documentation for more information on the available commands](https://docs.vagrantup.com/v2/cli/index.html).


## Installation


Clone the openproject repository into a subfolder openproject.

    git clone https://github.com/opf/openproject.git -b dev
    
Then, clone this repo

    git clone https://github.com/oliverguenther/openproject-docker-dev.git
    cd openproject-docker-dev    
    
 
Remove `.mac` or `.linux` from `docker-compose.yml<suffix>`. On the Mac, the volume commands are referring to the proxy filesystem, with which we need to synchronize our data through vagrant.
On Linux, you can directly use the host volumes.
Thus, we need separate configuration files for docker-compose for now.


As we use a database container, we can exploit the entries from docker-compose to the hosts file to refer to our database.
Copy the following configuration from `openproject-docker-dev/config/database.yml` to `openproject/config/database.yml`.

	default: &default
	  adapter: postgresql
	  encoding: unicode
	  pool: 5
	  host: postgres
	  port: 5432
	  username: openproject
	  password: openproject
	
	development:
	  <<: *default
	  database: openproject_dev
	
	test:
	  <<: *default
	  database: openproject_test


On Mac, bring up the VM, use `vagrant up`. This will synchronize the host directory with NFS.
To use the docker client on the Mac host, you still need to tell Docker where the daemon is running by executing:

    export DOCKER_HOST=tcp://localhost:2375

and run `docker-compose build` within it to build the OpenProject web image. It bases on the official [ruby-2.1.5](https://registry.hub.docker.com/_/ruby/) image. Initial installation thus might take a while.

    git clone https://github.com/oliverguenther/openproject-docker-dev.git
    cd openproject-docker-dev
    docker-compose build
    
Install the required gems and frontend packages with bundler using the data container:

    docker-compose run web bundle install
    docker-compose run web npm install
    
Bundler will install gems to a special location `/bundler`, which is backed by a persistent data container.

Finally, setup the PostgreSQL database with the following commands.

    docker-compose run web bundle exec rake db:create
    docker-compose run web bundle exec rake db:migrate
    docker-compose run web bundle exec rake db:seed

## Usage

To start the OpenProject web container and its linked database, simply execute

    docker-compose run --service-ports web


You can add the `-d` flag to detach the container from the foreground. Note that `docker-compose up` will not work due to gems requiring an interactive shell.

You can the visit the following URL in a browser on your host machine to get started:

    http://127.0.0.1:5000
    
### Data Synchronization

On Linux, no synchronization is needed, as the host filesystem is mounted directly. 
On Mac, the parent directory of the Vagrantfile is synced bi-directional with VM to the boot2docker VM.

[While rsync is a bit faster](https://github.com/blinkreaction/boot2docker-vagrant) on the Mac, the one-way synchronization causes some issues when installing node and bower modules to `frontend/`. While npm / bower paths can be adjusted, dependencies in the frontend files are not properly resolved.

### Update OpenProject code

To upgrade your OpenProject installation, simply pull on the homest machine and (let vagrant) sync the files if you're on Mac.

As on the host itself, you may need to update gems or database migrations.

    docker-compose run web bundle install
    docker-compose run web rake db:migrate

## Data persistence

The gems installed by the web container by bundler as well as the PostgreSQL data is *stored* in the data container, but not (directly) persisted anywhere on the host itself.

The application data itself is mounted using volumes in docker-compose.
For Mac, note that these mounts refer to the filesystem on the boot2docker/vagrant-boot2docker VM. Any data from the parent directory of the openproject-docker-dev directory on the host is shared to `/usr/src/openproject/dev/`.

On Linux, the volumes are directly shared from the parent directory to `/app/openproject`.

While docker-compose provides shared volumes from the host with the *volume* directive, this performs significantly worse on OSX due to the VM implementation.
A promising alternative is to look into NFS-based shared volumes (e.g., [boot2docker-vagrant](https://github.com/blinkreaction/boot2docker-vagrant)).

Until this is resolved, this image provides little use as a development platform, as there is no direct passing of code from the host to the image.

## Plugins

If you use or develop plugins, just add a `Gemfile.plugins` to your openproject root.
For local development, use the `:path` directive of bundler:


    gem "openproject-revisions_git", :path => '../plugins/openproject-revisions_git'

If the plugin code resides anywhere below the parent of `openproject-docker-dev`, it is available at `/app/openproject`, and thus the relative path doesn't break.

## License

Copyright (c) 2015 Oliver Günther (mail@oliverguenther.de)

Bases on the vagrant-boot2docker Vagrantfile. Copyright (c) 2015 blinkreaction

OpenProject is a project management system.
Copyright (C) 2013 the OpenProject Foundation (OPF)

This program is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License
version 3.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
