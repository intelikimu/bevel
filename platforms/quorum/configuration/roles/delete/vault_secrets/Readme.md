## delete/vault_secrets
This role deletes the Vault configurations
### main.yaml
### Tasks
(Variables with * are fetched from the playbook which is calling this role)
#### 1. Delete docker creds
This task deletes docker credentials.
##### Input Variables
    kind: Helmrelease, The kind of component
    namespace: Namespace of the component
    name: "regcred"
    state: absent ( This deletes any found result)
    kubeconfig: The config file of cluster
    context: The context of the cluster
**ignore_errors**: This flag ignores the any errors and proceeds furthur.

#### 2. Delete ambassador creds
This task deletes ambassador credentials.
##### Input Variables
    kind: Helmrelease, The kind of component
    namespace: Namespace of the component
    name: "Name of the ambassador credential"
    state: absent ( This deletes any found result)
    kubeconfig: The config file of cluster
    context: The context of the cluster
**ignore_errors**: This flag ignores the any errors and proceeds furthur.

#### 3. Delete vault-auth path
This task deletes vault auth.
##### Input Variables
    *VAULT_ADDR: Contains Vault URL, Fetched using 'vault.' from network.yaml
    *VAULT_TOKEN: Contains Vault Token, Fetched using 'vault.' from network.yaml
    *component_name: The name of resource
**shell** : This command deletes the vault auth.
**ignore_errors**: This flag ignores the any errors and proceeds furthur.

#### 3. Delete Crypto Material
This task deletes crypto material
##### Input Variables
    *VAULT_ADDR: Contains Vault URL, Fetched using 'vault.' from network.yaml
    *VAULT_TOKEN: Contains Vault Token, Fetched using 'vault.' from network.yaml
**shell** : This command deletes the secrets
