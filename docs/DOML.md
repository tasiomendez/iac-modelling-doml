# DevSecOps Model Language (DOML)

The aim of the DevSecOps Model Language (DOML) grammar is giving the necessary elements to use the resources previously defined in `*.rmdf` files. We can also define mapping among cloud providers, so we can work on an abstract layer without thinking in the requirements of an specific cloud provider.

| Keyword         | Required | Description                                            |
| --------------- | -------- | ------------------------------------------------------ |
| metadata        | yes      | Metadata description of the file                       |
| imports         | no       | Packages imported to be accessible from the given file |
| node_templates  | no       | Implementation of the resources                        |
| node_definition | no       | Mapping definition among cloud providers               |
| input           | no       | Input variables                                        |
| output          | no       | Output variables                                       |

>  The `metadata`, `imports` and `node_templates` take the same rules described for the previous grammar.

#### Nodes Definition

This provides the tool for mapping different nodes into several cloud providers, so we can define different nodes for each cloud provider and achieve an abstract representation of a given resource.

| Keyword     | Required | Type   | Description                |
| ----------- | -------- | ------ | -------------------------- |
| description | yes      | String | Description of the mapping |
| providers   | no       | dict   | Map of providers and nodes |

It should take into account that we need to import the necessary qualified names in order to use them.

```yaml
piacere.compute.VirtualMachine:
  description: '[...]'
  providers:
    aws: piacere.aws.modules.VirtualMachine
    azure: piacere.azure.modules.VirtualMachine
    gcp: piacere.gcp.modules.VirtualMachine
```

#### Input & Output Variables

Input variables make the blueprints dynamic, so we can have input variables which then can be used and that will be required when running the deployment. Output variables are values of certain attributes or properties that we want to know after the provisioning in order to know or to save.

The definition of the input variables are the same as for the properties. Output variables is just a dictionary key-value where the key is the name of the variable.

```yaml
input:
  vm_name:
    type: String
    description: 'Virtual Machine name'
    
output:
  ip: {{ get_attribute: virtual_machine.ip }}
```

#### Intrinsic Functions

On DOML we have more intrinsic functions than on RMDF as we would want to access attributes and input variables and not just properties and it was state on the previous section.

- `get_input` can be used to get the value of an input variable and assign it to a property.

  ```yaml
  virtual_machine_name: {{ get_input: vm_name }}
  ```


#### Overriding Default Values

When we are using a complex resource which is composed by several ones, we can may override a default value for a given node. Thus, within a given node, we can access to deeper properties and assign a value them. 

```yaml
wordpress:
  type: piacere.compute.VirtualMachine
  properties:
    virtual_machine_name: {{ get_input: vm_name }}
    location: {{ get_input: region_name }}
    # This allows to overwrite default values or to deeper properties
    azure.virtual_machine.delete_os_disk_on_termination: true
  relationships:
    connected_to: subnet
```

