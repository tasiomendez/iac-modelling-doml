package org.piacere.dsl.generator

import java.util.Map
import org.eclipse.emf.common.util.URI
import org.eclipse.emf.ecore.resource.Resource
import org.eclipse.xtext.generator.IFileSystemAccess2
import org.eclipse.xtext.generator.IGeneratorContext
import org.eclipse.xtext.resource.IResourceDescriptions
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
import org.piacere.dsl.rMDF.CSTRING
import org.piacere.dsl.rMDF.CValueExpression

class TerraformGenerator extends OrchestratorGenerator {
	
	final String fileExtension = ".tf"
	
	override void doGenerate(Resource resource, IFileSystemAccess2 fsa, IGeneratorContext context, IResourceDescriptions descriptions) {
		super.doGenerate(resource, fsa, context, descriptions)
		val filename = this.getFilename(resource.URI)
		fsa.generateFile(filename, resource.compile)
	}

	override getFilename(URI uri) {
		super.getFilename(uri) + this.fileExtension
	}

	override compile(Resource resource) '''
		«resource.header»
		
		««« inputs:
		«FOR i : resource.allContents.toIterable.filter(CInputVariable) BEFORE this.title("Input Variables")»
			«i.compile»
		«ENDFOR»
		
		«this.providers.compile»
		
		««« outputs:
		«FOR i : resource.allContents.toIterable.filter(COutputVariable) BEFORE this.title("Output Variables")»
			«i.compile»
		«ENDFOR»
		
	'''
	
	override compile(CMetadata metadata) {
		throw new UnsupportedOperationException()
	}
	
	override compile(Map<CProvider, Integer> providers) {
		var node_templates = '''
			«««	node_templates:
			«FOR n : this.root.nodes.nodes BEFORE this.title("Node Templates")»
						«n.compile(null)»
					«ENDFOR»
		'''
		return '''
			«FOR p : providers.keySet BEFORE this.title("Providers")»
				provider "«p.name»" {
					# This credentials should be changed with the correct ones
					# as secrets https://learn.hashicorp.com/tutorials/terraform/sensitive-variables
					«FOR f : p.features»
						«f.name» = <<«f.name.toUpperCase»>>
					«ENDFOR»
				}
				
			«ENDFOR»
			
			«node_templates»
		'''
	}

	override compile(CInputVariable variable) '''
		variable "«variable.name»" {
			«IF variable.data.type !== null»
				type        = «this.trim(variable.data.type?.predefined.toLowerCase)»
			«ENDIF»
			«IF variable.data.description !== null»
				description = "«this.trim(variable.data.description?.value)»"
			«ENDIF»
			«IF variable.data.^default !== null»
				default     = «this.getValueExpr(variable.data.^default, true)»
			«ENDIF»
		}
		
	'''

	override compile(CNodeTemplate node, CNodeTemplate _super) '''
		«IF node.template.type.data.nodes !== null»
			«FOR n : node.template.type.data.nodes.nodes»
				«n.compile(node)»
			«ENDFOR»
		«ELSE»
			resource "«this.transformName(node.template.type.name)»" "«node.name»" {
				«node.template.compile(_super?.template)»
			}
			
		«ENDIF»
	'''

	override compile(CNode node, CNode _super) '''
		«FOR p : node.properties»
			«p.compile»
		«ENDFOR»
		«IF _super !== null»
			«FOR p : _super?.properties.filter[CNodeProperty prop |
				this.providers.merge(node.type.provider, 1, [a, b | a + b])
				prop.name.node.name == node.type.name
			]»
				«p.compile»
			«ENDFOR»
		«ENDIF»
	'''

	override compile(CNodeProperty property) '''
		«IF property.value instanceof CNodeNestedProperty»
			«property.name.name» «(property.value as CNodeNestedProperty).compile»
		«ELSEIF property.value instanceof CMultipleValueExpression»
			«(property.value as CMultipleValueExpression).compile»
		«ELSE»
			«property.name.name» = «this.getPropertyValue(property.value)»
		«ENDIF»
	'''

	override compile(CNodeNestedProperty property) '''
		{
			«FOR p : property.properties»
				«p.compile»
			«ENDFOR»
		}
		
	'''

	override compile(COutputVariable variable) '''
		output "«variable.name»" {
			«IF variable.value !== null»
				value = "«this.getValueInlineSingle(variable.value as CNodePropertyValueInlineSingle)»"
			«ENDIF»
		}
		
	'''

	override compile(CConcatValues expr) '''
	«this.getValueInlineSingle(expr.first)»«FOR i : expr.list»«this.getValueInlineSingle(i as CNodePropertyValueInlineSingle)»«ENDFOR»'''

	override compile(CNodeCrossRefGetInput expr) '''
	${var.«expr.input.name»}'''

	override compile(CNodeCrossRefGetAttribute expr) '''
	${«this.transformName(expr.node.template.type.name)».«expr.node.name».«expr.attr»}'''

	override compile(CNodeCrossRefGetValue expr) '''
	"PENDING TO IMPLEMENT"'''

	override compile(CMultipleValueExpression expr) '''
		«IF expr.values.head instanceof CNodePropertyValueInlineSingle»
			«(expr.eContainer as CNodeProperty).name.name» = «FOR e : expr.values BEFORE '[ ' SEPARATOR ', ' AFTER ' ]'»«this.getValueInlineSingle(e as CNodePropertyValueInlineSingle)»«ENDFOR»
		«ELSEIF expr.values.head instanceof CMultipleNestedProperty»
			«FOR e : expr.values»
				«(expr.eContainer as CNodeProperty).name.name» {
					«(e as CMultipleNestedProperty).first.compile»
					«FOR r : (e as CMultipleNestedProperty).rest.properties»
						«r.compile»
					«ENDFOR»
				}
				
			«ENDFOR»
		«ENDIF»
		'''
	
	override getValueExpr(CValueExpression expr, Boolean quotes) {
		switch expr {
			CSTRING: '"' + expr.value + '"'
			default: super.getValueExpr(expr, quotes)
		}
	}

	def transformName(String name) {
		this.trim(name.replace(".", "_").toLowerCase)
	}

	def title(String title) '''
		#####################
		# «title» 
		#####################
		
	'''

}
