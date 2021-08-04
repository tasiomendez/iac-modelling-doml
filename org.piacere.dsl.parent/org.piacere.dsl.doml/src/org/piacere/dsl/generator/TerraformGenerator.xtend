package org.piacere.dsl.generator

import java.util.List
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
import org.piacere.dsl.rMDF.CConfigureDataVariable
import org.piacere.dsl.rMDF.CMetadata
import org.piacere.dsl.rMDF.CMultipleNestedProperty
import org.piacere.dsl.rMDF.CMultipleValueExpression
import org.piacere.dsl.rMDF.CNode
import org.piacere.dsl.rMDF.CNodeCrossRefGetAttribute
import org.piacere.dsl.rMDF.CNodeCrossRefGetValue
import org.piacere.dsl.rMDF.CNodeInterface
import org.piacere.dsl.rMDF.CNodeInterfaces
import org.piacere.dsl.rMDF.CNodeNestedProperty
import org.piacere.dsl.rMDF.CNodeProperty
import org.piacere.dsl.rMDF.CNodePropertyValue
import org.piacere.dsl.rMDF.CNodePropertyValueInlineSingle
import org.piacere.dsl.rMDF.CNodeRelationship
import org.piacere.dsl.rMDF.CNodeTemplate
import org.piacere.dsl.rMDF.CNodeTemplateLinks
import org.piacere.dsl.rMDF.CNodeType
import org.piacere.dsl.rMDF.CProperty
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
			«FOR n : this.root.nodes.nodes BEFORE this.title('Node Templates')»
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
		val tree = OrchestratorGenerator.getOrDefaultTreeTemplate(node, this.descriptions)
		val templates = tree.leaves.filter(tree)
		val interfaces = tree.interfaces
		
		return '''
			«FOR t : templates»
				resource "«t.root.template.type.resourceName»" "«this.trim(t.name)»" {
					«t.root.template.compile(t)»
					
					«FOR i : interfaces.keySet»
						«IF i.isChildren(t)»
							«interfaces.get(i).compile(t)»
						«ENDIF»
					«ENDFOR»
				}
				
			«ENDFOR»
		'''
	}
	
	def getResourceName(CNodeType type) {
		if (type.data.alias !== null)
			return this.transformName(type.data.alias)
		else return this.transformName(type.name)
	}

	override compile(CNode node, TreeNodeTemplate tree) {
		this.providers.merge(node.provider, 1, [a, b|a + b])
		val properties = tree.properties
		val relationships = tree.relationships
		
		return '''
			«FOR p : properties.keySet»
				«p.compile(properties.get(p), tree)»
			«ENDFOR»
			
			«FOR r : relationships.keySet»
				«relationships.get(r).compile(r, tree.root.links)»
			«ENDFOR»
		'''
	}
	
	override compile(CNodeRelationship r, QualifiedName name, List<CNodeTemplateLinks> links) {
		val target = OrchestratorGenerator.getOrDefaultTreeTemplate(r.value, this.descriptions)
		val leaves = target.leaves.filter[ leaf | 
			val types = links.map[ origin ]
			types.contains(leaf.root.template.type)
		]
		
		return '''
			«FOR c : leaves»
				«links.findFirst[ l |
					l.origin === c.root.template.type
				].property» = "${«c.root.template.type.resourceName».«name.skipLast(2).append(c.alias).segments.join('_')».«r.name.split('_').last»}" 
			«ENDFOR»
		'''
	}

	override compile(CProperty property, CNodePropertyValue value, TreeNodeTemplate tree) '''
		«IF value instanceof CNodeNestedProperty»
			«property.name» «(value as CNodeNestedProperty).compile(property, tree)»
		«ELSEIF value instanceof CMultipleValueExpression»
			«(value as CMultipleValueExpression).compile(tree)»
		«ELSE»
			«property.name» = «this.getPropertyValue(value, property, tree)»
		«ENDIF»
	'''

	override compile(CNodeNestedProperty property, CProperty definition, TreeNodeTemplate tree) {
		val properties = tree.resolveProperties(property, definition)
		return '''
			{
				«FOR p : properties.keySet»
					«p.compile(properties.get(p), tree)»
				«ENDFOR»
			}
			
		'''
	}
	
	override compile(CNodeInterfaces interfaces, TreeNodeTemplate tree) '''
		«IF interfaces !== null»
			«FOR i : interfaces.interfaces»
				«IF i.interface.configure.executor === tree.root.template.type»
					«i.compile(tree)»
				«ENDIF»
			«ENDFOR»
		«ENDIF»
	'''
	
	override compile(CNodeInterface nodeInterface, TreeNodeTemplate tree) '''
		provisioner "remote-exec" {
			inline = ["sudo apt update", "sudo apt install python3 -y", "echo Done!"]
			connection {
				host        = "<<HOST_IP>>"
				type        = "ssh"
				user        = "<<HOST_USERNAME>>"
				private_key = "<<HOST_PRIVATE_KEY>>"
			}
		}
		
		provisioner "local-exec" {
			command = <<EOT
		    ANSIBLE_HOST_KEY_CHECKING=False \
		    ansible-playbook \
		    -u <<HOST_USERNAME>> \
		    -i '<<HOST_IP>>,' \
		    --private-key '<<HOST_PRIVATE_KEY>>' \
		    «nodeInterface.extraVars(tree)»
		    «nodeInterface.interface.configure.path.value»
			EOT
		}
	'''
	
	def extraVars(CNodeInterface nodeInterface, TreeNodeTemplate tree) '''
		«IF !nodeInterface.interface.configure.data.empty»
			--extra-vars "{ \
			«FOR d : nodeInterface.interface.configure.data»
				«d.compile(tree)»
			«ENDFOR»
			}" \
		«ENDIF»
	'''
	
	override compile(CConfigureDataVariable data, TreeNodeTemplate tree) {
		val properties = tree.resolveProperties(data, null)
		return '''
			«FOR p : properties.values»
				"«data.name»": «this.getPropertyValue(p, null, tree)», \
			«ENDFOR»
		'''
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
	"${var.«expr.input.name»}"'''

	override compile(CNodeCrossRefGetAttribute expr) '''
	"${«expr.node.template.type.resourceName».«this.trim(expr.node.name)».«expr.attr»}"'''
	
	override compile(CNodeCrossRefGetValue expr) '''
	## MISSING VALUE <<«expr.crossvalue.name.toUpperCase»>> ##'''

	override compile(CMultipleValueExpression expr, TreeNodeTemplate tree) '''
		«IF expr.values.head instanceof CNodePropertyValueInlineSingle»
			«(expr.eContainer as CNodeProperty).name.name» = «FOR e : expr.values BEFORE '[ ' SEPARATOR ', ' AFTER ' ]'»«this.getValueInlineSingle(e as CNodePropertyValueInlineSingle)»«ENDFOR»
		«ELSEIF expr.values.head instanceof CMultipleNestedProperty»
			«FOR e : expr.values»
				«(expr.eContainer as CNodeProperty).name.name» {
					«(e as CMultipleNestedProperty).compile((expr.eContainer as CNodeProperty).name, tree)»
				}
				
			«ENDFOR»
		«ENDIF»
	'''
	
	override compile(CMultipleNestedProperty property, CProperty definition, TreeNodeTemplate tree) {
		val properties = tree.resolveProperties(property, definition)
		return '''
			«FOR p : properties.keySet»
				«p.compile(properties.get(p), tree)»
			«ENDFOR»
		'''
	}

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
