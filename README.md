### README: Kubernetes Installation Script

---

## Overview

This repository provides a shell script, `install_k8s.sh`, for setting up a Kubernetes cluster on **Red Hat Enterprise Linux 8** servers using `kubeadm`. The script automates the installation and configuration of the following components:

- `containerd` (as the container runtime)
- Kubernetes tools: `kubeadm`, `kubelet`, `kubectl`
- Pod network add-on: **Calico**
- Cluster initialization with `kubeadm`

---

## Features

- Automates the installation of all necessary Kubernetes components.
- Configures `containerd` with `systemdCgroup`.
- Installs and configures `crictl` for managing containers.
- Pulls the required `pause` image (`registry.k8s.io/pause:3.9`).
- Sets up and initializes the Kubernetes control plane.
- Deploys the Calico pod network for cluster communication.

---

## Requirements

- **Operating System**: Red Hat Enterprise Linux 8
- **User Privileges**: Must be run with `sudo` privileges.
- **Network Access**: Ensure the server has internet access for downloading required packages and images.

---

## Usage

### 1. **Download the Script**

Save the script as `install_k8s.sh` on your server.

### 2. **Make the Script Executable**

Run the following command to grant execute permissions:
```bash
chmod +x install_k8s.sh
```

### 3. **Run the Script**

Execute the script with `sudo`:
```bash
sudo ./install_k8s.sh
```

### 4. **Provide Input**

During execution, the script will prompt you for the following details:
- **API Server Address**: The IP address of the control plane node.
- **Pod Network CIDR**: The IP range for the pod network (e.g., `192.168.0.0/16` for Calico).

---

## Example Run

Here’s an example of running the script:
```bash
sudo ./install_k8s.sh
```

Sample prompts and responses:
```
Enter the API server advertise address (e.g., 10.2.0.4): 10.2.0.4
Enter the Pod Network CIDR (e.g., 192.168.0.0/16): 192.168.0.0/16
```

---

## Script Workflow

1. Updates system packages and installs prerequisites.
2. Disables swap for Kubernetes compatibility.
3. Configures kernel modules and system settings required for Kubernetes.
4. Installs and configures `containerd` as the container runtime.
5. Configures `crictl` to use `containerd`.
6. Installs Kubernetes components (`kubeadm`, `kubelet`, `kubectl`).
7. Pulls the required `pause` image.
8. Initializes the Kubernetes control plane with `kubeadm`.
9. Deploys the Calico pod network.
10. Verifies the installation.

---

## Post-Installation Steps

1. **Check Node Status**
   Verify that the node is ready:
   ```bash
   kubectl get nodes
   ```

2. **Verify Pod Network**
   Ensure Calico pods are running:
   ```bash
   kubectl get pods -n kube-system
   ```

3. **Join Worker Nodes**
   To add worker nodes, run the `kubeadm join` command displayed after initialization on each worker node.

---

## Troubleshooting

- **Pause Image Mismatch**: Ensure `registry.k8s.io/pause:3.9` is pulled and configured in `containerd`.
- **Network Issues**: Verify firewall rules and ensure required ports (e.g., `6443`, `10250`) are open.
- **Kubelet Issues**: Check kubelet logs for errors:
  ```bash
  journalctl -u kubelet -f
  ```

---

## Additional Information

- **Container Runtime**: The script configures `containerd` with `systemdCgroup` enabled.
- **Pod Network Add-On**: Calico is deployed for pod networking; modify the script if you prefer another add-on.

---

## License

This script is open-source and can be used or modified freely. Attribution is appreciated.

---

Let me know if you need further customization or additional sections in the README! 🚀
