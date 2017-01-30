# -*- mode: ruby -*-
# vi: set ft=ruby :

# All Vagrant configuration is done below. The "2" in Vagrant.configure
# configures the configuration version (we support older styles for
# backwards compatibility). Please don't change it unless you know what
# you're doing.
Vagrant.configure("2") do |config|
  # The most common configuration options are documented and commented below.
  # For a complete reference, please see the online documentation at
  # https://docs.vagrantup.com.

  # Every Vagrant development environment requires a box. You can search for
  # boxes at https://atlas.hashicorp.com/search.
  # we use centos official
  # https://atlas.hashicorp.com/centos/boxes/7
  config.vm.box = "centos/7"

  # Disable automatic box update checking. If you disable this, then
  # boxes will only be checked for updates when the user runs
  # `vagrant box outdated`. This is not recommended.
  # config.vm.box_check_update = false

  # Create a forwarded port mapping which allows access to a specific port
  # within the machine from a port on the host machine. In the example below,
  # accessing "localhost:8080" will access port 80 on the guest machine.
  config.vm.network "forwarded_port", guest: 8888, host: 8888

  # Create a private network, which allows host-only access to the machine
  # using a specific IP.
  # config.vm.network "private_network", ip: "192.168.33.10"

  # Create a public network, which generally matched to bridged network.
  # Bridged networks make the machine appear as another physical device on
  # your network.
  # config.vm.network "public_network"

  # Share an additional folder to the guest VM. The first argument is
  # the path on the host to the actual folder. The second argument is
  # the path on the guest to mount the folder. And the optional third
  # argument is a set of non-required options.
  # config.vm.synced_folder "../data", "/vagrant_data"

  # the centos/7 box uses rsync by default, for windows you'll want to disable it
  if Vagrant::Util::Platform.windows? then
    config.vm.synced_folder ".", "/vagrant", disabled: true
  end

  # Provider-specific configuration so you can fine-tune various
  # backing providers for Vagrant. These expose provider-specific options.
  # Example for VirtualBox:
  #
  # config.vm.provider "virtualbox" do |vb|
  #   # Display the VirtualBox GUI when booting the machine
  #   vb.gui = true
  #
  #   # Customize the amount of memory on the VM:
  #   vb.memory = "1024"
  # end
  #
  # View the documentation for the provider you are using for more
  # information on available options.

  # Define a Vagrant Push strategy for pushing to Atlas. Other push strategies
  # such as FTP and Heroku are also available. See the documentation at
  # https://docs.vagrantup.com/v2/push/atlas.html for more information.
  # config.push.define "atlas" do |push|
  #   push.app = "YOUR_ATLAS_USERNAME/YOUR_APPLICATION_NAME"
  # end

  # Enable provisioning with a shell script. Additional provisioners such as
  # Puppet, Chef, Ansible, Salt, and Docker are also available. Please see the
  # documentation for more information about their specific syntax and use.
  # config.vm.provision "shell", inline: <<-SHELL
  #   apt-get update
  #   apt-get install -y apache2
  # SHELL

  # Required Environment Variables
  if ENV['init_role']
    $init_role = ENV['init_role']
  else
    puts "Environment variable: 'init_role' is not set, defaulting to 'dockerhost'"
    $init_role = 'dockerhost'
  end

  if ENV['init_env']
    $init_env = ENV['init_env']
  else
    puts "Environment variable: 'init_env' is not set, defaulting to 'dev'"
    $init_env = 'dev'
  end

  # Optional Environment Variables
  if ENV['init_repouser']
    $init_repouser = ENV['init_repouser']
  else
    puts "Environment variable: 'init_repouser' is not set, defaulting to 'neilmillard'"
    $init_repouser = 'neilmillard'
  end

  if ENV['init_reponame']
    $init_reponame = ENV['init_reponame']
  else
    puts "Environment variable: 'init_reponame' is not set, defaulting to 'puppet-dockerhost'"
    $init_reponame = 'puppet-dockerhost'
  end

  if ENV['init_repobranch']
    $init_repobranch = ENV['init_repobranch']
  else
    puts "Environment variable: 'init_repobranch' is not set, defaulting to 'master'"
    $init_repobranch = 'master'
  end

  args = "--role #{$init_role} --environment #{$init_env} --repouser #{$init_repouser} --reponame #{$init_reponame} --repobranch #{$init_repobranch}"

  config.vm.provision :shell, :path => 'provision.sh', :args => args
end
