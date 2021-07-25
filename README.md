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

