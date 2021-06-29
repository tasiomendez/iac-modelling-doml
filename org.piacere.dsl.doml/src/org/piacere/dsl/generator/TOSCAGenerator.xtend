package org.piacere.dsl.generator

import org.eclipse.emf.common.util.URI
import org.eclipse.emf.ecore.resource.Resource
import org.eclipse.xtext.generator.IFileSystemAccess2
import org.eclipse.xtext.generator.IGeneratorContext
import org.piacere.dsl.dOML.CInputVariable
import org.piacere.dsl.dOML.CNodeCrossRefGetInput
import org.piacere.dsl.dOML.COutputVariable
import org.piacere.dsl.rMDF.CConcatValues
import org.piacere.dsl.rMDF.CMetadata
import org.piacere.dsl.rMDF.CNode
import org.piacere.dsl.rMDF.CNodeCrossRefGetAttribute
import org.piacere.dsl.rMDF.CNodeCrossRefGetValue
import org.piacere.dsl.rMDF.CNodeNestedProperty
import org.piacere.dsl.rMDF.CNodeProperty
import org.piacere.dsl.rMDF.CNodePropertyValueInlineSingle
import org.piacere.dsl.rMDF.CNodeTemplate

class TOSCAGenerator extends DOMLGenerator {
	
	override void doGenerate(Resource resource, IFileSystemAccess2 fsa, IGeneratorContext context) {
		val filename = this.getFilename(resource.URI)
		fsa.generateFile(filename, resource.compile)
	}
	
	override getFilename(URI uri) {
		super.getFilename(uri) + '.yml'
	}
	
	override compile(Resource resource) '''
		«resource.header»
		
		tosca_definitions_version: cloudify_dsl_1_3
		
		«FOR m : resource.allContents.toIterable.filter(CMetadata)»
			«m.compile»
		«ENDFOR»	
		
		imports:
			- http://cloudify.co/spec/cloudify/4.5.5/types.yaml
			
		««« inputs:
		«FOR i : resource.allContents.toIterable.filter(CInputVariable) BEFORE 'inputs: \n'»
			
				«i.compile»
		«ENDFOR»
		
		«««	node_templates:
		«FOR n : resource.root.nodes.nodes BEFORE 'node_templates: \n'»
			
				«n.compile»
		«ENDFOR»
		
		««« outputs:
		«FOR i : resource.allContents.toIterable.filter(COutputVariable) BEFORE 'outputs: \n'»
			
				«i.compile»
		«ENDFOR»
		
	'''

	override compile(CMetadata metadata) '''
		description: >
			«metadata.description.value»
	'''

	override compile(CInputVariable variable) '''
		«variable.name»:
			«IF variable.data.type !== null»
				type: «this.trim(variable.data.type?.predefined.toLowerCase)»
			«ENDIF»
			«IF variable.data.description !== null»
				description: «this.trim(variable.data.description?.value)»
			«ENDIF»
			«IF variable.data.^default !== null»
				default: «this.getValueExpr(variable.data.^default, false)»
			«ENDIF»
	'''

	override compile(CNodeTemplate node) '''
		«IF node.template.type.data.nodes !== null»
			«FOR n : node.template.type.data.nodes.nodes»
				«n.compile»
			«ENDFOR»
		«ELSE»
			«node.name»:
				«node.template.compile»
				
		«ENDIF»
	'''

	override compile(CNode node) '''
		type: «this.trim(node.type.name)»
		properties:
			«FOR p : node.properties»
				«p.compile»
			«ENDFOR»
	'''

	override compile(CNodeProperty property) '''
		«property.name.name»: 
	'''

	override compile(CNodeNestedProperty property) '''
		«FOR p : property.properties»
			«p.compile»
		«ENDFOR»
	'''

	override compile(COutputVariable variable) '''
		«variable.name»:
			«IF variable.value !== null»
				value: «this.getValueExprInline(variable.value as CNodePropertyValueInlineSingle)»
			«ENDIF»
	'''

	override compile(CConcatValues expr) '''
		{ concat: [ 
					«this.getValueExprInline(expr.first)»«FOR i : expr.list BEFORE ',' SEPARATOR ','»
						«this.getValueExprInline(i as CNodePropertyValueInlineSingle)»«ENDFOR» ] }
	'''

	override compile(CNodeCrossRefGetInput expr) '''
		{ get_input: «expr.input.name» }
	'''

	override compile(CNodeCrossRefGetAttribute expr) '''
		{ get_attr: [ «expr.node.name», «expr.attr» ] }
	'''

	override compile(CNodeCrossRefGetValue expr) '''
		"PENDING TO IMPLEMENT"
	'''
	
}