Vagrant.require_version ">= 1.6.0"

Vagrant.configure("2") do |config|
  config.vm.define "boot2docker"

  config.vm.box = "dduportal/boot2docker"
  config.vm.box_check_update = false

  # Don't insert the user's own key
  config.ssh.insert_key = false

  # Forward unicorn web port
  config.vm.network :forwarded_port, host: 5000, guest: 5000

  vagrant_root = File.dirname(__FILE__)
  vagrant_config_path = File.expand_path('vagrant.yml')
  require 'yaml'
  ymlconf = YAML::load_file(vagrant_config_path)

  project_root = File.expand_path('../', vagrant_root)
  config.vm.synced_folder project_root, "/usr/src/openproject/",
    type: "nfs",
    mount_options: ["nolock", "vers=3", "tcp"]
    
  config.nfs.map_uid = Process.uid
  config.nfs.map_gid = Process.gid

  config.vm.provider "virtualbox" do |v|
    v.gui = false
    v.name = ymlconf['vm']['name']
    v.cpus = ymlconf['vm']['cpus']
    v.memory = ymlconf['vm']['memory']
  end

  ## Provisioning scripts ##
  # Allow Mac OS X docker client to connect to Docker without TLS auth
  # https://github.com/deis/deis/issues/2230#issuecomment-72701992
  config.vm.provision "shell" do |s|
    s.inline = <<-SCRIPT
      echo 'DOCKER_TLS=no' >> /var/lib/boot2docker/profile
      /etc/init.d/docker restart
    SCRIPT
  end
end
