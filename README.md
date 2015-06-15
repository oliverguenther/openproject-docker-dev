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
4. A host-side script to automate unison / fswatch synchronization such as [Hodor](https://github.com/gansbrest/hodor).
5. A wrapper script to patch boot2docker with a synchronization engine. Two prominent examples are [dinghy](https://github.com/codekitchen/dinghy) and [docker-osx-dev](https://github.com/brikis98/docker-osx-dev).

For a while, this repo included the workaround based on Vagrant. But this required some mangling with the paths and introduces Feel free to use a different method on Mac.

Instead I now suggest to use [docker-osx-dev](https://github.com/brikis98/docker-osx-dev), instead.
You still need boot2docker

To install the boot2docker virtual machine to run docker.
I recommend installing it through homebrew, which allows you to install [docker and docker-compose](https://docs.docker.com/compose/install/). in one go.

	brew install boot2docker docker docker-compose
	
Then, install `docker-osx-dev` with the following commands:

    curl -o /usr/local/bin/docker-osx-dev https://raw.githubusercontent.com/brikis98/docker-osx-dev/master/src/docker-osx-dev
    chmod +x /usr/local/bin/docker-osx-dev
    docker-osx-dev install

## Installation

Clone the openproject repository into a subfolder openproject.

    git clone https://github.com/opf/openproject.git -b dev
    
Then, clone this repo

    git clone https://github.com/oliverguenther/openproject-docker-dev.git
    cd openproject-docker-dev    
    

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


On Mac, prepare synchronization with rsync using  `docker-osx-dev`. This will synchronize the host directory with rsync.
It will keep running and watching for changes on the host side.

In a new tab, run `docker-compose build` build the OpenProject web image and its dependencies. It bases on the official [ruby-2.1.6](https://registry.hub.docker.com/_/ruby/) image. Initial installation thus might take a while.

Once the build step is completed, the following steps will install the required gems and frontend packages with bundler using the data container:

    docker-compose run web bundle install
    docker-compose run web npm install
    
Bundler will install gems to a special location `/bundler`, which is backed by a persistent data container.

Finally, setup the PostgreSQL database with the following commands.

    docker-compose run web bundle exec rake db:create
    docker-compose run web bundle exec rake db:migrate
    docker-compose run web bundle exec rake db:seed

## Usage

To start the OpenProject web container with foreman and its linked database, simply execute

    docker-compose up

You can also spawn a shell on the container and start foreman manually:

    docker-compose run --service-ports web bash

The `--service-ports` flag will ensure that exposed ports from the Dockerfile will be available to the host.

On Mac, `docker-osx-dev` writes a host entry for `dockerhost`, so you can the visit the following URL in a browser to get started:

    http://dockerhost:5000
    
On Linux, the port is forwarded to the host directly, so exposed ports are available on localhost.
    

### Update OpenProject code

To upgrade your OpenProject installation, simply pull on the host machine and let docker-osx-dev sync the files if you're on Mac.

On the container, you may need to update gems, node modules or database migrations, as you would on the host itself.
Re-run the above commands when necessary.

## Data persistence

The gems installed by the web container by bundler as well as the PostgreSQL data is *stored* in the data container, but not (directly) persisted anywhere on the host itself.

The application data itself is mounted using volumes in docker-compose.
For Mac, note that these mounts also refer to the filesystem on the boot2docker/vagrant-boot2docker VM. Any data from the parent directory of the openproject-docker-dev directory on the host is shared to `/app/`.

On Linux, the volumes are directly shared from the parent directory to `/app/`.

## Plugins

If you use or develop plugins, just add a `Gemfile.plugins` to your openproject root.
For local development, use the `:path` directive of bundler:


    gem "openproject-revisions_git", :path => '../plugins/openproject-revisions_git'

If the plugin code resides anywhere below the parent of `openproject-docker-dev`, it is available at `/app/openproject`, and thus is accessible with a relative path.

## License

Copyright (c) 2015 Oliver Günther (mail@oliverguenther.de)

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
