Vagrant.configure("2") do |config|
    config.hostmanager.enabled = true
    config.hostmanager.manage_host = true
  
    # Shared folder for storing the join command (if needed later)
    config.vm.synced_folder ".", "/vagrant", create: true
  
      
    ### Master Node ###
    config.vm.define "k8smaster" do |master|
      master.vm.box = "spox/ubuntu-arm"
      master.vm.hostname = "k8smaster.learndocker.xyz"
      master.vm.network "private_network", ip: "192.168.1.103"
      master.vm.provider "vmware_desktop" do |vmware|
        vmware.gui = true
        vmware.allowlist_verified = true
        vmware.memory = 4096
        vmware.cpus = 2
      end
      master.vm.provision "shell", path: "master.sh"
    end

    worker_ips = ["192.168.1.104"]
  
    ### Worker Nodes ###
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
        worker.vm.provision "shell", inline: <<-SHELL
          if [ -f /vagrant/configs/join.sh ]; then
            sudo bash /vagrant/configs/join.sh
          else
            echo "Join script not found. Ensure the master node is provisioned and the join script is generated."
          fi
        SHELL
      end
    end

  end
  