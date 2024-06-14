require 'yaml'
require 'erb'

# Load settings from the YAML file
settings = YAML.load_file('settings.yaml')

# Helper method to render ERB templates with variables
def render_template(template, variables)
  ERB.new(template).result_with_hash(variables)
end

Vagrant.configure("2") do |config|
  # Ensure the logs directory exists
  config.vm.provision "shell", inline: <<-SHELL
    mkdir -p /vagrant/logs
  SHELL

  # Enable and manage host entries
  config.hostmanager.enabled = true
  config.hostmanager.manage_host = true

  # Shared folder between host and VM
  config.vm.synced_folder ".", "/vagrant", create: true

  # Increase boot timeout to 10 minutes
  config.vm.boot_timeout = 600

  # Ensure new SSH key is inserted for security
  config.ssh.insert_key = true

  # Master and worker node configurations from settings
  master_ip = settings['master_ip']
  master_hostname = "k8smaster.learndocker.xyz"
  worker_ips = settings['worker_ips']

  # VM resource settings
  memory = settings['vm']['memory']
  cpus = settings['vm']['cpus']

  # Render CNI Calico URL with the specified version
  cni_calico = render_template(settings['cni']['calico'], { calico_version: settings['cni']['calico_version'] })

  # Master node configuration
  config.vm.define "k8smaster" do |master|
    master.vm.box = "spox/ubuntu-arm"
    master.vm.hostname = master_hostname
    master.vm.network "private_network", ip: master_ip
    master.vm.provider "vmware_desktop" do |vmware|
      vmware.gui = true
      vmware.allowlist_verified = true
      vmware.memory = memory
      vmware.cpus = cpus
    end
    master.vm.provision "shell", path: "scripts/master.sh", env: {
      "MASTER_IP" => master_ip,
      "MASTER_HOSTNAME" => master_hostname,
      "CNI_CALICO" => cni_calico,
      "METRICS_SERVER" => settings['metrics_server'],
      "K8S_VERSION" => settings['k8s']['version']
    }
  end

  # Worker nodes configuration
  worker_ips.each_with_index do |ip, index|
    config.vm.define "k8sworker#{index + 1}" do |worker|
      worker.vm.box = "spox/ubuntu-arm"
      worker.vm.hostname = "k8sworker#{index + 1}.learndocker.xyz"
      worker.vm.network "private_network", ip: ip
      worker.vm.provider "vmware_desktop" do |vmware|
        vmware.gui = true
        vmware.allowlist_verified = true
        vmware.memory = memory
        vmware.cpus = cpus
      end
      worker.vm.provision "shell", path: "scripts/node.sh", env: {
        "K8S_VERSION" => settings['k8s']['version']
      }
    end
  end
end
