# DOML Language Definition

This repository contains the definition files for DevOps Modelling Language (DOML) using XText for Eclipse. DOML models different infrastructure environments, by means of abstractions hiding the specificities and technicalities of the current solutions.

There are two different grammars defined in this repository which are related in order to re-use blocks of code which are in common. The aim of the RMDF grammar is defining resources on the concrete infrastructure layer. The DOML grammar allows the user to use these resources in order to describe application's components and how they relate to each other.

## Installation

This software requires to have installed [Eclipse](https://www.eclipse.org/downloads/) and Java. It also requires to install Xtext, a framework for development of programming languages and domain-specific languages and Xpect, a unit- and integration-testing framework based in JUnit.

### Installing Xtext

[Xtext](https://www.eclipse.org/Xtext/download.html) should be installed in Eclipse. In the website, an instance of Eclipse with Xtext already installed can be found. Otherwise, it can be installed into a running Eclipse.

1. Go to Help > Install new software... and Add...
   `http://download.eclipse.org/modeling/tmf/xtext/updates/composite/releases/`
2. Select the Xtext SDK from the category Xtext and complete the wizard by clicking the Next button until you can click Finish.
3. Restart Eclipse and Xtext will be ready to use.

### Installing Xpect

[Xpect](http://www.xpect-tests.org/), as Xtext, should be installed in Eclipse following the same steps.

1. Go to Help > Install new software... and Add...
   `https://ci.eclipse.org/xpect/job/Xpect/job/master/lastSuccessfulBuild/artifact/org.eclipse.xpect.releng/p2-repository/target/repository/`
2. Select the Xpect SDK from the version you want to install and complete the wizard by clicking the Next button until you can click Finish.
3. Restart Eclipse and Xpect will be ready to use.
   To use Xpect, if you don't have the language installed, launch a runtime workbench where it is installed.

### Compile and Build DOML

Prerequisites: Eclipse 4.19 (2021-03) which requires Java 11 or newer JRE/JDK, XText 2.25.0 or newer and Xpect 0.2.0 (for testing purposes).

1. Clone this repository into your computer.

   ```shell
   git clone git@github.com:tasiomendez/iac-modelling-doml.git
   ```

2. Import the `org.piacere.dsl.parent` project into Eclipse as a Maven project along with all the modules.

3. Set target platform to `/org.piacere.dsl.target/org.piacere.dsl.target.target` in Preferences > Plug-in Development > Target Platform.

4. Run `/org.piacere.dsl.rmdf/src/org/piacere/dsl/GenerateRMDF.mwe2` as *Run As > MWE2 Workflow*

5. Run `/org.piacere.dsl.doml/src/org/piacere/dsl/GenerateDOML.mwe2` as *Run As > MWE2 Workflow*

6. Now your projects should be without errors markers. Sometimes, even after these steps, several projects still have error markers. However, this is a refresh problem in Eclipse. Simply clean build the projects with error markers will solve the issues.

This action generates the parser and text editor and some additional infrastructure code. We are now able to test the Eclipse IDE integration. If you right-click the project `org.piacere.dsl.doml` in the Package Explorer and select *Run As > Eclipse Application*, a new run configuration is created and launched that starts a second instance of Eclipse including the language plug-ins.

1. Import into Eclipse the `org.piacere.dsl.examples` project.
2. The editor is ready. Now you can write using all the modules provided in the project. The source code for Terraform and Tosca will be generated into the `src-gen` folder.

For using Xpect for testing purposes, we should import into Eclipse the projects: (I) `/org.piacere.dsl.parent/org.piacere.dsl.rmdf.tests` for rmdf and (II) `/org.piacere.dsl.parent/org.piacere.dsl.doml.tests` for doml.

- If you do a right mouse click onto the file and choose "Open with" in the menu, there are three editors available: (1) An Xpect+Xtext editor with highlighting, content assist, etc. for both your language and the Xpect syntax. (2) An Xpect editor with support for the Xpect syntax. (3) The editor for your language that you build.
- Running the Java class as JUnit test executes the test cases specified in the `filename.doml.xt` file.
- If a test fails, double-clicking on it in the JUnit view opens a comparison editor which compares the test's expectation with the actual test result. This eases understanding why a test fails dramatically.
- In the context menu of a test in the JUnit view, you can select "Go to XPECT" to open and select test case in the DSL-File.

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

## DevSecOps Model Language (DOML)

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

