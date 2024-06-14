require 'yaml'
require 'erb'

settings = YAML.load_file('settings.yaml')

def render_template(template, variables)
  ERB.new(template).result_with_hash(variables)
end

Vagrant.configure("2") do |config|
  config.hostmanager.enabled = true
  config.hostmanager.manage_host = true

  config.vm.synced_folder ".", "/vagrant", create: true
  config.vm.boot_timeout = 600  # Increase timeout to 10 minutes
  config.ssh.insert_key = true  # Ensure new SSH key is inserted

  master_ip = settings['master_ip']
  master_hostname = "k8smaster.learndocker.xyz"
  worker_ips = settings['worker_ips']

  memory = settings['vm']['memory']
  cpus = settings['vm']['cpus']

  cni_calico = render_template(settings['cni']['calico'], { calico_version: settings['cni']['calico_version'] })

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
    master.vm.provision "shell", path: "master.sh", env: {
      "MASTER_IP" => master_ip,
      "MASTER_HOSTNAME" => master_hostname,
      "CNI_CALICO" => cni_calico,
      "METRICS_SERVER" => settings['metrics_server'],
      "K8S_VERSION" => settings['k8s']['version']
    }
  end

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
      worker.vm.provision "shell", path: "node.sh", env: {
        "K8S_VERSION" => settings['k8s']['version']
      }
    end
  end
end
