## ROLE: k8-component
This roles check if Namespace, Clusterrolebinding or StorageClass is created or not.

### Tasks
(Variables with * are fetched from the playbook which is calling this role)
#### 1. Wait for {{ component_type }} {{ component_name }}
Task to check if Namespace, Clusterrolebinding and StorageClass is created. This task will try for a maximum of 10 times with an interval of 35 seconds between each try
##### Input Variables

    *component_type: The type of resource/organisation.
    *component_ns: The organisation's namespace
    kubernetes.config_file: The kubernetes config file
    kubernetes.context: The kubernetes current context

**retries**: It means this task will check the kubernetes resources being deployed or not for a maximum time of retries mentioned i.e 10. 
**delay**:  It means each retry will happen at a gap of mentioned delay i.e 35 seconds.
**until**:  It runs untill *component_data.resources|length* > 0, i.e. it will keep on retrying untill said resource is up within mentioned retries.
**when**:  It runs when *component_type* == "Namespace" or *component_type* == "ClusterRoleBinding" or *component_type* == "StorageClass", i.e. this task will run for Namespace, Clusterrolebinding or StorageClass .

##### Output Variables

    component_data: This variable stores the output whether the k8s resources are up and running or not.

#### 2. Wait for {{ component_type }} {{ component_name }}
Task to check if ServiceAccount is created. This task will try for a maximum of 10 times with an interval of 35 seconds between each try
##### Input Variables

    *component_type: The type of resource/organisation.
    *component_ns: The organisation's namespace
    kubernetes.config_file: The kubernetes config file
    kubernetes.context: The kubernetes current context

**retries**: It means this task will check the said kubernetes resources being deployed or not for a maximum time of retries mentioned i.e 10. 
**delay**: It means each retry will happen at a gap of mentioned delay i.e 35 seconds.
**until**: It runs untill *component_data.resources|length* > 0, i.e. it will keep on retrying untill said resource if up within mentioned retries.
**when**: It runs when *component_type* == "ServiceAccount" , i.e. this task will run for ServiceAccount.

##### Output Variables

    component_data: This variable stores the output whether the ServiceAccount is created or not.