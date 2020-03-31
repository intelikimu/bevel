Install Pre-requisites
=====================

Before we begin, if you haven't already done so, you may wish to check that
you have all the prerequisites below installed on the platform(s)
on which you'll be deploying blockchain networks from and/or operating
the Blockchain Automation Framework.

## Git Repository
As you may have read in the [key concepts](keyconcepts), the Blockchain Automation Framework (BAF) uses GitOps method for deployment to Kubernetes clusters. So, a Git repository is needed for BAF (this can be a [GitHub](https://github.com/) repository as well).

The Operator should have full access to the Git Repository. 

## Kubernetes
The Blockchain Automation Framework (BAF) deploys the DLT network on [Kubernetes](https://kubernetes.io/) clusters; so to use BAF, at least one Kubernetes cluster should be available.
BAF recommends one Kubernetes cluster per organization for production-ready projects. 
Also, a user needs to make sure that the Kubernetes clusters can support the number of pods and persistent volumes that will be created by BAF.

---
**NOTE:** For the current release, BAF has been tested on Amazon EKS with Kubernetes version 1.12. Currently Indy is only tested on Kubernetes Cluster of AWS instances with Kubernetes version 1.16 and also you need AWS cli credentials.

---

Please follow [Amazon instructions](https://aws.amazon.com/eks/getting-started/) to set-up your required Kubernetes cluster(s).
To connect to Kubernetes cluster(s), you would also need kubectl Command Line Interface (CLI). Please refer [here](https://kubernetes.io/docs/tasks/tools/install-kubectl/) for installation instructions, although the Blockchain Automation Framework configuration code (Ansible scripts) installs this automatically.

## HashiCorp Vault
In this current release, [Hashicorp Vault](https://www.vaultproject.io/) is mandatory for the Blockchain Automation Framework (BAF) as the certificate and key storage solution; so to use BAF, at least one Vault server should be available. BAF recommends one Vault per organization for production-ready projects. 

Follow [official instructions](https://www.vaultproject.io/docs/install/) to deploy Vault in your environment. 

---
**NOTE:** Recommended approach is to create one Vault deployment on one VM and configure the backend as a cloud storage.

---

## Docker

The Blockchain Automation Framework does not provision any pre-built docker images, instead, various Dockerfiles are provided, so a user is free to change them. A user needs to install [Docker CLI](https://docs.docker.com/install/) to make sure the environment has the capbility of building these Dockerfiles to generate various docker images. Platform specific docker image details are mentioned [here](./operations/configure_prerequisites.md).

---
**NOTE:** The Blockchain Automation Framework uses minimum Docker version 18.03.0

---

You can check the version of Docker you have installed with the following
command from a terminal prompt:
```
    docker --version
```

Also, the user needs to provision their own docker registry, username and password for storing these docker images. Information such as registry url etc. need to be configured in a [network.yaml file](./operations/fabric_networkyaml.md).

## Docker Build

The Blockchain Automation Framework configuration is essentially Ansible scripts, create a containerized Ansible machine to deploy the DLT network using docker build.  

The details on how to create a containerized Ansible machine is mentioned [here](./developer/docker-build.md).

---
**NOTE:** This containerized machine (also called **Ansible Controller**) should have connectivity to the Kubernetes cluster(s) and the Hashicorp Vault service(s). Which means, if your Vault is behind a bastion, you have to create the ssh-tunnel from inside the running baf-build container.

---

## Internet Domain
As you may have read in the [Kubernetes key concepts](keyConcepts/kubernetes), the Blockchain Automation Framework uses [Ambassador](https://www.getambassador.io/about/why-ambassador/) or [HAProxy Ingress Controller](https://www.haproxy.com/documentation/hapee/1-9r1/traffic-management/kubernetes-ingress-controller/) for inter-cluster communication. So, for the Kubernetes services to be available outside the specific cluster, at least one DNS Domain is required. This domain name can then be sub-divided across multiple clusters and the domain-resolution configured for each.
Although for production implementations, each organization (and thereby each cluster), must have one domain name.

---
**NOTE:** If single cluster is being used for all organizations in a dev/POC environment, then domain name is not needed.

---

## Ansible

*Optional*   

If you are not using docker build you can install Ansible manually on the machine from which you will deploy the DLT network. This can be a local machine as long as Ansible commands can run on it.

Please note that this machine (also called **Ansible Controller**) should have connectivity to the Kubernetes cluster(s) and the Hashicorp Vault service(s).  

And it is essential to install the [git client](https://git-scm.com/download) on the Ansible Controller.  

---
**NOTE:** The Blockchain Automation Framework requires minimum **Ansible version 2.8.1**

**NOTE (MacOS):** Ansible requires GNU tar. Install it on MacOS through Homebrew `brew install gnu-tar`

---
Follow [official instructions](https://docs.ansible.com/ansible/latest/installation_guide/intro_installation.html) to install Ansible in a new environment.

### Configuring Ansible Inventory file

In the Blockchain Automation Framework, we connect to Kubernetes cluster through the **Ansible Controller** and do not modify or connect to any other machine directly. The Blockchain Automation Framework's sample inventory file is located [here](https://github.com/hyperledger-labs/blockchain-automation-framework/tree/master/platforms/shared/inventory/ansible_provisoners). 

Add the contents of this file in your Ansible host configuration file (typically in file /etc/ansible/hosts).

Read more about Ansible inventory [here](https://docs.ansible.com/ansible/latest/user_guide/intro_inventory.html)

---
**NOTE :** We suggest using docker build. 

---