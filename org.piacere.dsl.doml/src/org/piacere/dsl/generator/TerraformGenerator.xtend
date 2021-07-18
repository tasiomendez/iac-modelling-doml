package org.piacere.dsl.generator

import java.util.Map
import org.eclipse.emf.common.util.URI
import org.eclipse.emf.ecore.resource.Resource
import org.eclipse.xtext.generator.IFileSystemAccess2
import org.eclipse.xtext.generator.IGeneratorContext
import org.eclipse.xtext.naming.QualifiedName
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
import org.piacere.dsl.rMDF.CNodeRelationship
import org.piacere.dsl.rMDF.CNodeTemplate
import org.piacere.dsl.rMDF.CProvider
import org.piacere.dsl.rMDF.CSTRING
import org.piacere.dsl.rMDF.CValueExpression
import org.piacere.dsl.utils.TreeNodeTemplate

class TerraformGenerator extends OrchestratorGenerator {

	final String fileExtension = ".tf"

	override void doGenerate(Resource resource, IFileSystemAccess2 fsa, IGeneratorContext context,
		IResourceDescriptions descriptions) throws Exception {
		super.doGenerate(resource, fsa, context, descriptions)
		val filename = this.getFilename(resource.URI)
		try {
			fsa.generateFile(filename, resource.compile)
		} catch (Exception e) {
			fsa.generateFile(filename, e.compile(resource))
			throw e
		}
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
				«n.compile»
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

	override compile(CNodeTemplate node) {
		val tree = new TreeNodeTemplate(
			node,
			QualifiedName.create(node.name),
			node.template.properties.toSet,
			this.descriptions
		)
		val templates = tree.templates
		return '''
			«FOR t : templates»
				resource "«this.transformName(t.root.template.type.name)»" "«this.trim(t.name)»" {
					«t.root.template.compile(t)»
				}
				
			«ENDFOR»
		'''
	}

	override compile(CNode node, TreeNodeTemplate tree) '''
		«FOR p : tree.properties»
			«p.compile»
		«ENDFOR»
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
	
	override compile(CNodeRelationship relationship) {
		throw new UnsupportedOperationException()	
	}

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
	${«this.transformName(expr.node.template.type.name)».«this.trim(expr.node.name)».«expr.attr»}'''

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
