package org.piacere.dsl.generator

import java.util.List
import java.util.Map
import org.eclipse.emf.common.util.URI
import org.eclipse.emf.ecore.resource.Resource
import org.eclipse.emf.ecore.util.EcoreUtil
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
import org.piacere.dsl.rMDF.CNodeEdge
import org.piacere.dsl.rMDF.CNodeInterface
import org.piacere.dsl.rMDF.CNodeInterfaces
import org.piacere.dsl.rMDF.CNodeNestedProperty
import org.piacere.dsl.rMDF.CNodePropertyValue
import org.piacere.dsl.rMDF.CNodeRelationship
import org.piacere.dsl.rMDF.CNodeTemplate
import org.piacere.dsl.rMDF.CProperty
import org.piacere.dsl.rMDF.CProvider
import org.piacere.dsl.utils.TreeNodeTemplate

class XMIGenerator extends OrchestratorGenerator {
	
	final String fileExtension = ".xmi"

	override void doGenerate(Resource resource, IFileSystemAccess2 fsa, IGeneratorContext context,
		IResourceDescriptions descriptions) throws Exception {
		super.doGenerate(resource, fsa, context, descriptions)
		val filename = fsa.getURI(this.getFilename(resource.URI))
		filename.toString.save(resource)
	}

	override getFilename(URI uri) {
		super.getFilename(uri) + this.fileExtension
	}
	
	def save(String filename, Resource resource) {
		EcoreUtil.resolveAll(resource)
		val Resource xmiResource = resource.resourceSet.createResource(URI.createURI(filename))
		xmiResource.getContents().add(resource.getContents().get(0))
		xmiResource.save(null)	
	}
	
	override compile(Resource resource) {
		throw new UnsupportedOperationException()
	}
	
	override compile(CMetadata metadata) {
		throw new UnsupportedOperationException()
	}
	
	override compile(CInputVariable variable) {
		throw new UnsupportedOperationException()
	}
	
	override compile(CNodeTemplate node) {
		throw new UnsupportedOperationException()
	}
	
	override compile(CNode node, TreeNodeTemplate tree) {
		throw new UnsupportedOperationException()
	}
	
	override compile(CNodeRelationship r, QualifiedName name, List<CNodeEdge> edges) {
		throw new UnsupportedOperationException()
	}
	
	override compile(CProperty property, CNodePropertyValue value, TreeNodeTemplate tree) {
		throw new UnsupportedOperationException()
	}
	
	override compile(CNodeNestedProperty property, CProperty definition, TreeNodeTemplate tree) {
		throw new UnsupportedOperationException()
	}
	
	override compile(COutputVariable variable) {
		throw new UnsupportedOperationException()
	}
	
	override compile(CNodeInterfaces interfaces, TreeNodeTemplate tree) {
		throw new UnsupportedOperationException()
	}
	
	override compile(CNodeInterface nodeInterface, TreeNodeTemplate tree) {
		throw new UnsupportedOperationException()
	}
	
	override compile(CConfigureDataVariable data, TreeNodeTemplate tree) {
		throw new UnsupportedOperationException()
	}
	
	override compile(Map<CProvider, Integer> providers) {
		throw new UnsupportedOperationException()
	}
	
	override compile(CConcatValues expr) {
		throw new UnsupportedOperationException()
	}
	
	override compile(CNodeCrossRefGetInput expr) {
		throw new UnsupportedOperationException()
	}
	
	override compile(CNodeCrossRefGetAttribute expr) {
		throw new UnsupportedOperationException()
	}
	
	override compile(CNodeCrossRefGetValue expr) {
		throw new UnsupportedOperationException()
	}
	
	override compile(CMultipleValueExpression expr, TreeNodeTemplate tree) {
		throw new UnsupportedOperationException()
	}
	
	override compile(CMultipleNestedProperty property, CProperty definition, TreeNodeTemplate tree) {
		throw new UnsupportedOperationException()
	}
	
}