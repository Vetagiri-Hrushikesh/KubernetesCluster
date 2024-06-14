Vagrant.configure("2") do |config|
  config.hostmanager.enabled = true
  config.hostmanager.manage_host = true

  config.vm.synced_folder ".", "/vagrant", create: true
  config.vm.boot_timeout = 600  # Increase timeout to 10 minutes
  config.ssh.insert_key = true  # Ensure new SSH key is inserted

  master_ip = "192.168.1.103"
  worker_ips = ["192.168.1.104"]

  config.vm.define "k8smaster" do |master|
    master.vm.box = "spox/ubuntu-arm"
    master.vm.hostname = "k8smaster.learndocker.xyz"
    master.vm.network "private_network", ip: master_ip
    master.vm.provider "vmware_desktop" do |vmware|
      vmware.gui = true
      vmware.allowlist_verified = true
      vmware.memory = 4096
      vmware.cpus = 2
    end
    master.vm.provision "shell", path: "master.sh"
  end

  worker_ips.each_with_index do |ip, index|
    config.vm.define "k8sworker#{index + 1}" do |worker|
      worker.vm.box = "spox/ubuntu-arm"
      worker.vm.hostname = "k8sworker#{index + 1}.learndocker.xyz"
      worker.vm.network "private_network", ip: ip
      worker.vm.provider "vmware_desktop" do |vmware|
        vmware.gui = true
        vmware.allowlist_verified = true
        vmware.memory = 4096
        vmware.cpus = 2
      end
      worker.vm.provision "shell", path: "node.sh"
    end
  end
end
