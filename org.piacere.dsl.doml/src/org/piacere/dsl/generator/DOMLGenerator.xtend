/*
 * generated by Xtext 2.25.0
 */
package org.piacere.dsl.generator

import com.google.inject.Inject
import org.eclipse.emf.common.util.URI
import org.eclipse.emf.ecore.EObject
import org.eclipse.emf.ecore.resource.Resource
import org.eclipse.xtext.EcoreUtil2
import org.eclipse.xtext.generator.AbstractGenerator
import org.eclipse.xtext.generator.IFileSystemAccess2
import org.eclipse.xtext.generator.IGeneratorContext
import org.eclipse.xtext.resource.IEObjectDescription
import org.eclipse.xtext.resource.IResourceDescriptions
import org.piacere.dsl.dOML.CBOOLEAN
import org.piacere.dsl.dOML.CInputVariable
import org.piacere.dsl.dOML.CNodeCrossRefGetInput
import org.piacere.dsl.dOML.COutputVariable
import org.piacere.dsl.dOML.DOMLModel
import org.piacere.dsl.rMDF.CConcatValues
import org.piacere.dsl.rMDF.CFLOAT
import org.piacere.dsl.rMDF.CIntrinsicFunctions
import org.piacere.dsl.rMDF.CMetadata
import org.piacere.dsl.rMDF.CNode
import org.piacere.dsl.rMDF.CNodeCrossRefGetAttribute
import org.piacere.dsl.rMDF.CNodeCrossRefGetValue
import org.piacere.dsl.rMDF.CNodeNestedProperty
import org.piacere.dsl.rMDF.CNodeProperty
import org.piacere.dsl.rMDF.CNodePropertyValue
import org.piacere.dsl.rMDF.CNodePropertyValueInlineSingle
import org.piacere.dsl.rMDF.CNodeTemplate
import org.piacere.dsl.rMDF.CNodeType
import org.piacere.dsl.rMDF.CSIGNEDINT
import org.piacere.dsl.rMDF.CSTRING
import org.piacere.dsl.rMDF.CValueExpression
import org.piacere.dsl.rMDF.RMDFModel
import org.piacere.dsl.rMDF.RMDFPackage

/**
 * Generates code from your model files on save.
 * 
 * See https://www.eclipse.org/Xtext/documentation/303_runtime_concepts.html#code-generation
 */
class DOMLGenerator extends AbstractGenerator {

	@Inject
	IResourceDescriptions descriptions;
	
	String author = "Tasio Mendez (Politecnico di Milano)"
	String email = "tasio.mendez@mail.polimi.it"

	override void doGenerate(Resource resource, IFileSystemAccess2 fsa, IGeneratorContext context) {
		val tosca = new TOSCAGenerator()
		tosca.doGenerate(resource, fsa, context)
		val terraform = new TerraformGenerator()
		terraform.doGenerate(resource, fsa, context)
	}
	
	def header(Resource resource) '''
		# Auto-generated file with PIACERE 
		# Project URL: https://cordis.europa.eu/project/id/101000162/es
		#
		## Filename: �getFilename(resource.URI)� 
		## Author: �this.author�
		##         �this.email�
	'''

	def compile(Resource resource) '''
	''' 

	def compile(CMetadata metadata) '''
	'''

	def compile(CInputVariable variable) '''
	'''

	def compile(CNodeTemplate node) '''
	'''

	def compile(CNode node) '''
	'''

	def compile(CNodeProperty property) '''
	'''

	def compile(CNodeNestedProperty property) '''
	'''

	def compile(COutputVariable variable) '''
	'''

	def getValueProperty(CNodePropertyValue value) {
		switch value {
			CNodeNestedProperty: value.compile
			CNodePropertyValueInlineSingle: this.getValueExprInline(value)
		}
	}

	def getValueExpr(CValueExpression expr, Boolean quotes) {
		switch expr {
			CSTRING case quotes: '"' + expr.value + '"'
			CSTRING: expr.value
			CFLOAT case quotes: '"' + expr.value + '"'
			CFLOAT: expr.value
			CBOOLEAN case quotes: '"' + expr.value + '"'
			CBOOLEAN: expr.value
			CSIGNEDINT case quotes: '"' + expr.value + '"'
			CSIGNEDINT: expr.value
			default: ''
		}
	}

	def getValueExprInline(CNodePropertyValueInlineSingle expr) {
		switch expr {
			CValueExpression: this.getValueExpr(expr, true)
			CIntrinsicFunctions: this.getIntrinsicFunction(expr)
			default: ''
		}
	}

	def getIntrinsicFunction(CIntrinsicFunctions func) {
		switch func {
			CConcatValues: func.compile
			CNodeCrossRefGetInput: func.compile
			CNodeCrossRefGetAttribute: func.compile
			CNodeCrossRefGetValue: func.compile
		}
	}

	def compile(CConcatValues expr) '''
	'''

	def compile(CNodeCrossRefGetInput expr) '''
	'''

	def compile(CNodeCrossRefGetAttribute expr) '''
	'''

	def compile(CNodeCrossRefGetValue expr) '''
	'''

	def getRoot(Resource r) {
		EcoreUtil2.getRootContainer(r.allContents.toIterable.get(0)) as DOMLModel
	}

	def getProviderImplementations(CNodeType node) {
		val exported = descriptions.getExportedObjectsByType(RMDFPackage.Literals.CNODE_TYPE)
		return exported.map [ IEObjectDescription t |
			EcoreUtil2.resolve(t.getEObjectOrProxy(), node) as CNodeType
		].filter [ CNodeType n |
			n.data?.superType?.name === node.name
		].toMap([ CNodeType n |
			this.getProvider(n)
		])
	}

	def getProvider(EObject obj) {
		val root = EcoreUtil2.getRootContainer(obj)
		return switch root {
			RMDFModel: root.metadata.provider
			DOMLModel: root.metadata.provider
		}
	}

	def getFilename(URI uri) {
		var filename = uri.toString
		filename = filename.replace("platform:/resource", "")
		filename = filename.substring(filename.indexOf('/', 1) + 1).replaceFirst('/', ".");
		return filename
	}

	def trim(String value) {
		return value.trim
	}
}
