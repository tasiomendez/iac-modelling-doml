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
class RMDFFileTemplateProvider implements IFileTemplateProvider {
	override getFileTemplates() {
		#[new NodeTypeTemplate, new ProviderTemplate]
	}
}

@FileTemplate(label="Node type template", icon="file_template.png", description="Create a node type template for RMDF.")
final class NodeTypeTemplate {

	override generateFiles(IFileGenerator generator) {
		generator.generate('''�folder�/�name�.rmdf''', '''
			metadata:
			  _version: '0.0.1'
			  
			node_types:
			
			  �name�:
			    description: ''
		''')
	}
}

@FileTemplate(label="Provider template", icon="file_template.png", description="Create a provider template for RMDF.")
final class ProviderTemplate {
	
	override generateFiles(IFileGenerator generator) {
		generator.generate('''�folder�/�name�.rmdf''', '''
			metadata:
			  _version: '0.0.1'
			  
			provider:
			
			  alias: �name�
			  features:
			  
			    username:
			      type: String
			      description: ''
			      
			    password:
			      type: String
			      description: ''

		''')
	}
	
}