/*
 * generated by Xtext 2.25.0
 */
package org.piacere.dsl.ui.wizard


import org.eclipse.xtext.ui.wizard.template.FileTemplate
import org.eclipse.xtext.ui.wizard.template.IFileGenerator
import org.eclipse.xtext.ui.wizard.template.IFileTemplateProvider

/**
 * Create a list with all file templates to be shown in the template new file wizard.
 * 
 * Each template is able to generate one or more files.
 */
class DOMLFileTemplateProvider implements IFileTemplateProvider {
	override getFileTemplates() {
		#[new DOMLTemplateFile]
	}
}

@FileTemplate(label="DOML basic compute template", icon="file_template.png", description="Create a basic template for DOML.")
final class DOMLTemplateFile {

	override generateFiles(IFileGenerator generator) {
		generator.generate('''�folder�/�name�.doml''', '''
			metadata:
			  _version: '0.0.1'
			  
			imports:
			  - piacere.compute.*
			 
			input:
			  
			  name:
			    type: String
			    description: 'Virtual Machine name'
			  
			  location:
			    type: String
			    description: 'Location name'
			  
			node_templates: 
			
			  �name�:
			    type: piacere.compute.Node
			    properties: 
			      name: {{ get_input: name }}
			      location: {{ get_input: location }}
		''')
	}
}