package org.piacere.dsl.generator

import java.util.Map
import org.eclipse.emf.common.util.URI
import org.eclipse.emf.ecore.resource.Resource
import org.eclipse.xtext.generator.IFileSystemAccess2
import org.eclipse.xtext.generator.IGeneratorContext
import org.piacere.dsl.dOML.CInputVariable
import org.piacere.dsl.dOML.CNodeCrossRefGetInput
import org.piacere.dsl.dOML.COutputVariable
import org.piacere.dsl.rMDF.CConcatValues
import org.piacere.dsl.rMDF.CMetadata
import org.piacere.dsl.rMDF.CMultipleNestedProperty
import org.piacere.dsl.rMDF.CMultipleValueExpression
import org.piacere.dsl.rMDF.CNode
import org.piacere.dsl.rMDF.CNodeCrossRefGetAttribute
import org.piacere.dsl.rMDF.CNodeCrossRefGetValue
import org.piacere.dsl.rMDF.CNodeNestedProperty
import org.piacere.dsl.rMDF.CNodeProperty
import org.piacere.dsl.rMDF.CNodePropertyValueInlineSingle
import org.piacere.dsl.rMDF.CNodeTemplate
import org.piacere.dsl.rMDF.CProvider

class TOSCAGenerator extends OrchestratorGenerator {
	
	final String fileExtension = ".yml"

	override void doGenerate(Resource resource, IFileSystemAccess2 fsa, IGeneratorContext context) {
		super.doGenerate(resource, fsa, context)
		val filename = this.getFilename(resource.URI)
		fsa.generateFile(filename, resource.compile)
	}

	override getFilename(URI uri) {
		super.getFilename(uri) + this.fileExtension
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
		
		«this.providers.compile»
		
		««« outputs:
		«FOR i : resource.allContents.toIterable.filter(COutputVariable) BEFORE 'outputs: \n'»
			
				«i.compile»
		«ENDFOR»
		
	'''

	override compile(CMetadata metadata) '''
		description: >
			«metadata.description.value»
	'''
	
	override compile(Map<CProvider, Integer> providers) {
		var node_templates = '''
			«««	node_templates:
			«FOR n : this.root.nodes.nodes BEFORE 'node_templates: \n'»
						
							«n.compile(null)»
					«ENDFOR»
		'''
		return '''
			«FOR p : providers.keySet BEFORE 'dsl_definitions: \n'»
				
					// This credentials should be changed with the correct ones
					// as secrets https://docs.cloudify.co/latest/working_with/manager/using-secrets/
					«p.name»_config: &«p.name»_config
						«FOR f : p.features»
							«f.name»: <<«f.name.toUpperCase»>>
						«ENDFOR»
			«ENDFOR»
			
			«node_templates»
		'''
	}
	
	def getDSLDefinition(CProvider provider) {
		this.providers.merge(provider, 1, [a, b | a + b])
		return '''
			«provider.name»_config: *«provider.name»_config
		'''
	}

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

	override compile(CNodeTemplate node, CNodeTemplate _super) '''
		«IF node.template.type.data.nodes !== null»
			«FOR n : node.template.type.data.nodes.nodes»
				«n.compile(node)»
			«ENDFOR»
		«ELSE»
			«node.name»:
				«node.template.compile(_super?.template)»
				
		«ENDIF»
	'''

	override compile(CNode node, CNode _super) '''
		type: «this.trim(node.type.name)»
		properties:
			«node.type.provider.DSLDefinition»
			«FOR p : node.properties»
				«p.compile»
			«ENDFOR»
			«IF _super !== null»
				«FOR p : _super?.properties.filter[CNodeProperty prop |
					prop.name.node.name === node.type.name
				]»
					«p.compile»
				«ENDFOR»
			«ENDIF»
	'''

	override compile(CNodeProperty property) '''
		«property.name.name»: «this.getPropertyValue(property.value)»
	'''

	override compile(CNodeNestedProperty property) '''
		
			«FOR p : property.properties»
				«p.compile»
			«ENDFOR»
	'''

	override compile(COutputVariable variable) '''
		«variable.name»:
			«IF variable.value !== null»
				value: «this.getValueInlineSingle(variable.value as CNodePropertyValueInlineSingle)»
			«ENDIF»
	'''

	override compile(CConcatValues expr) '''
		{ concat: [ 
					«this.getValueInlineSingle(expr.first)»«FOR i : expr.list BEFORE ',' SEPARATOR ','»
						«this.getValueInlineSingle(i as CNodePropertyValueInlineSingle)»«ENDFOR» ] }
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

	override compile(CMultipleValueExpression expr) '''
		
			«FOR e : expr.values»
				«IF e instanceof CNodePropertyValueInlineSingle»
					- «this.getValueInlineSingle(e)»
				«ELSEIF e instanceof CMultipleNestedProperty»
					- «e.first.compile»
					  «FOR r : e.rest.properties»
					  	«r.compile»
					  «ENDFOR»
				«ENDIF»
			«ENDFOR»
	'''

}
