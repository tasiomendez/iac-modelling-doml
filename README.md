# DOML Language Definition

This repository contains the definition files for DevOps Modelling Language (DOML) using XText for Eclipse. DOML models different infrastructure environments, by means of abstractions hiding the specificities and technicalities of the current solutions.

There are two different grammars defined in this repository which are related in order to re-use blocks of code which are in common. The aim of the RMDF grammar is defining resources on the concrete infrastructure layer. The DOML grammar allows the user to use these resources in order to describe application's components and how they relate to each other.

- Resource definitions, modules and some examples can be found on [tasiomendez/iac-modelling-modules](https://github.com/tasiomendez/iac-modelling-modules/tree/master/src/org/piacere/) repository. 

## Resource Model Definition (RMDF)

This aim of the Resource Model Definition (RMDF) grammar is defining different resources and instances on a given cloud provider. It is also used to define data types which are used by the different components. The definition of the resources takes different parameters. 

| Key        | Required | Description                                            |
| ---------- | -------- | ------------------------------------------------------ |
| metadata   | yes      | Metadata description of the file                       |
| imports    | no       | Packages imported to be accessible from the given file |
| data_types | no       | Data structures definition                             |
| node_types | yes      | Nodes and resources definition                         |

#### Metadata

The *metadata* tag goal is to define different information about the file where the resources are described such as the provider, the version of the file and a description.

| Keyname      | Required | Type   | Description                                                 |
| ------------ | -------- | ------ | ----------------------------------------------------------- |
| _provider    | yes      | String | The name of the provider                                    |
| _version     | yes      | String | Version of the file, which allows to have a control-version |
| _description | no       | String | Description of the purpose of the file                      |

#### Imports

All node types are accessible from any file. However, in order to take advantage of the imports and reducing the scope of all the declared resources, it is needed to import the packages we want to use. Thus, the packages can be imported singingly or by importing all the resources which hang from a certain location.

```yaml
imports:
  - piacere.azure.compute.VirtualMachine    # Imports only the VirtualMachine node from Azure
  - piacere.azure.compute.*                 # Imports all the compute nodes from Azure
  - piacere.azure.*                         # Imports all the nodes from Azure
```

#### Node Types

Nodes are the main element from RMDF Language which are an abstract representation of a resource on the cloud. We can define a resource by giving a name as a qualified name, so it can be imported following the rules described in the previous section.

For defining a resource we need to set a description (which can be empty) and a set of properties. We can also build complex resources by combining different ones and setting the relationships among them.

| Keyname        | Required | Type   | Description                                                  |
| -------------- | -------- | ------ | ------------------------------------------------------------ |
| description    | yes      | String | The description of the resource definition                   |
| properties     | no       | dict   | The set of properties we will be able to set later on        |
| node_templates | no       | dict   | Used for defining complex resources which are dependent of others |

```yaml
piacere.azure.network.NetworkSecurityGroup:
  description: '[...]'
  properties:
    name:
      type: String
      description: 'Specifies the name of the network security group.'
      required: true

    location:
      type: String
      description: 'Specifies the supported Azure location where the resource exists.'
      required: true

    security_rules:
      type: piacere.azure.data.SecurityRule
      multiple: true
      description: 'List of objects SecurityRule'
```

For defining a property, we need to set the following fields depending on what we want to declare.

| Keyname     | Required | Type             | Description                                                  |
| ----------- | -------- | ---------------- | ------------------------------------------------------------ |
| type        | yes      | Type \| DataType | Type of the property value (string, boolean, integer or a custom data type) |
| default     | no       | \<any>           | The default value for the property                           |
| description | no       | String           | The description of the variable which will be displayed when hovering |
| required    | no       | Boolean          | If the property is required true, otherwise false            |
| multiple    | no       | Boolean          | If the property could take multiple values set it to true, otherwise false |

#### Data Types

Data types allows the user to define new data structures to use on nodes, which will as defining nested properties, as for each property defined, only primitive types are allowed. An example of using a data type would be defining a security rule structure for a firewall if those are defined within a property of the firewall. 

| Keyname     | Required | Type   | Description                                                  |
| ----------- | -------- | ------ | ------------------------------------------------------------ |
| description | no       | String | Description of the data type                                 |
| properties  | yes      | dict   | Set of description of the properties for the given data type |

```yaml
piacere.azure.data.SecurityRule:
  description: '[...]'
  properties:
    name:
      type: String
      description: '[...]'
      required: true

    priority:
      type: Integer
      required: true
      description: '[...]'
      
    ...
```

#### Node Templates



#### Intrinsic Functions

Some intrinsic functions are provided which can be used within the blueprints. This functions makes the blueprint dynamic, being able to take values from other fields in order to fill some other ones.

- `get_value` provides the functionality to take the value given to a property within the `node_templates` tag in order to inherit the value and spread it downwards. It can refer to the properties of the resource being declared

  ```yaml
  piacere.azure.modules.Subnet:
    description: '[...]'
    properties: 
      subnet_name:
        type: String
        description: '[...]'
        required: true
    node_templates:
      subnet:
        type: piacere.azure.network.Subnet
        properties:
          name: {{ get_value: subnet_name }}
  ```

## DevSecOps Model Language (DOML)

[...]
