# openproject-docker
#
# OpenProject as a docker container with docker-compose
# Copyright (c) 2015 Oliver Günther (mail@oliverguenther.de)
#
# OpenProject is a project management system.
# Copyright (C) 2013 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# version 3.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
FROM ruby:2.1.5

# Would like to specify those two in the yml,
# but that isn't implemented yet
# https://github.com/docker/docker/pull/9176
ENV OP_ROOT /app/openproject
ENV RAILS_ENV development

# Choose newer npm / nodejs
RUN curl -sL https://deb.nodesource.com/setup | bash -

# Build deps
RUN apt-get update
RUN apt-get install -y \
  git apt-transport-https curl build-essential zlib1g-dev \
  memcached libffi-dev libyaml-dev libssl-dev postgresql-client \
  nodejs \
  --no-install-recommends && rm -rf /var/lib/apt/lists/*

# Fix npm bug
# https://github.com/npm/npm/issues/6309
RUN npm -g install npm@next

# Install foreman
RUN gem install foreman

# Install bower
RUN npm -g install bower

# Install remote debugger (RubyMine)
RUN gem install ruby-debug-ide

# Allow bower to run as root and set path
COPY config/.bowerrc /root/.bowerrc

# Allow npm to run as root and set path
COPY config/.npmrc /root/.npmrc

# Bundler path
RUN bundle config path /bundler

WORKDIR $OP_ROOT

CMD HOST=0.0.0.0 PORT=3000 foreman start -f Procfile.dev -c web=1,assets=1,worker=0

