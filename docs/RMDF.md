# Resource Model Definition (RMDF)

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

The `node_templates` tag can be used withing a node type in order to define a more complex structure of a resource. On this way, we can abstract some infrastructure configuration giving default values to some properties and exposing other ones when using it.

| Keyword       | Required | Type                | Description                                                  |
| ------------- | -------- | ------------------- | ------------------------------------------------------------ |
| type          | yes      | Node Type Reference | The type of the node declared. It must be noted that it should be imported before using |
| properties    | no       | dict                | Dictionary of properties assigning a value to them           |
| relationships | no       | dict                | Dictionary of relationships to other nodes within the same block |

```yaml
piacere.aws.modules.Firewall:
  description: 'Deploy a Firewall on Amazon Web Services'
  properties:
    ingress:
      type: piacere.aws.data.SecurityRule
      description: 'Configuration rules for ingress traffic.'
      multiple: true
       
    egress:
      type: piacere.aws.data.SecurityRule
      description: 'Configuration rules for egress traffic.'
      multiple: true
    
  node_templates:
    security_group:
      type: piacere.aws.ec2.SecurityGroup
      properties:
        name: 'security-group'
  
    security_group_rules:
      type: piacere.aws.ec2.SecurityGroupRules
      properties:
        ingress: {{ get_value: ingress }}
        egress: {{ get_value: egress }}
      relationships:
        connected_to: security_group
```

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

- `get_attribute` can be used to access an attribute of a given node on this way `<name_of_the_node>.<attr>`

  ```yaml
  ip: {{ get_attribute: virtual_machine.ip }}
  ```

  where `virtual_machine` is the name of the node, and `ip` is the name of the attribute.

- `concat` can be used to concatenate strings and values

  ```yaml
  path: {{ concat: "/user/", {{ get_value: username }}, "/.ssh/" }}
  ```

