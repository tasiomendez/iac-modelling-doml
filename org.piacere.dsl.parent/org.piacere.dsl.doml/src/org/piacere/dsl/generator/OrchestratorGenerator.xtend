package org.piacere.dsl.generator

import java.text.SimpleDateFormat
import java.util.Collections
import java.util.Date
import java.util.HashMap
import java.util.Map
import org.eclipse.emf.common.util.URI
import org.eclipse.emf.ecore.EObject
import org.eclipse.emf.ecore.resource.Resource
import org.eclipse.xtext.EcoreUtil2
import org.eclipse.xtext.generator.IFileSystemAccess2
import org.eclipse.xtext.generator.IGeneratorContext
import org.eclipse.xtext.resource.IResourceDescriptions
import org.piacere.dsl.dOML.CInputVariable
import org.piacere.dsl.dOML.CNodeCrossRefGetInput
import org.piacere.dsl.dOML.COutputVariable
import org.piacere.dsl.dOML.DOMLModel
import org.piacere.dsl.rMDF.CBOOLEAN
import org.piacere.dsl.rMDF.CConcatValues
import org.piacere.dsl.rMDF.CConfigureDataVariable
import org.piacere.dsl.rMDF.CFLOAT
import org.piacere.dsl.rMDF.CIntrinsicFunctions
import org.piacere.dsl.rMDF.CMetadata
import org.piacere.dsl.rMDF.CMultipleNestedProperty
import org.piacere.dsl.rMDF.CMultipleValueExpression
import org.piacere.dsl.rMDF.CNode
import org.piacere.dsl.rMDF.CNodeCrossRefGetAttribute
import org.piacere.dsl.rMDF.CNodeCrossRefGetValue
import org.piacere.dsl.rMDF.CNodeInterface
import org.piacere.dsl.rMDF.CNodeInterfaces
import org.piacere.dsl.rMDF.CNodeNestedProperty
import org.piacere.dsl.rMDF.CNodePropertyValue
import org.piacere.dsl.rMDF.CNodePropertyValueInline
import org.piacere.dsl.rMDF.CNodePropertyValueInlineSingle
import org.piacere.dsl.rMDF.CNodeTemplate
import org.piacere.dsl.rMDF.CNodeType
import org.piacere.dsl.rMDF.CProperty
import org.piacere.dsl.rMDF.CProvider
import org.piacere.dsl.rMDF.CSIGNEDINT
import org.piacere.dsl.rMDF.CSTRING
import org.piacere.dsl.rMDF.CValueExpression
import org.piacere.dsl.rMDF.RMDFModel
import org.piacere.dsl.utils.TreeNodeTemplate

abstract class OrchestratorGenerator {
		
	val author = "Tasio Mendez"
	val email = "tasio.mendez@mail.polimi.it"
	val formatter = new SimpleDateFormat("dd-MM-yyyy HH:mm")
	
	protected IResourceDescriptions descriptions
	
	protected Map<CProvider, Integer> providers
	protected CProvider defaultProvider
	protected DOMLModel root
	
	protected static Map<String, TreeNodeTemplate> templates = new HashMap<String, TreeNodeTemplate>()
					
	def void doGenerate(Resource resource, IFileSystemAccess2 fsa, IGeneratorContext context, IResourceDescriptions descriptions) throws Exception {
		this.descriptions = descriptions
		
		this.providers = new HashMap<CProvider, Integer>()
		this.defaultProvider = resource.root.metadata.provider
		this.root = resource.root
	}
			
	def header(Resource resource) '''
		# Auto-generated file 
		# Copyright (c) 2021 Politecnico di Milano
		#
		##     Filename: «this.getFilename(resource.URI)»
		##  Create date: «this.formatter.format(new Date())»
		##       Author: «this.author» <«this.email»>
	'''
	
	def error(Exception e, Resource resource, IFileSystemAccess2 fsa) {
		val filename = this.getFilename(resource.URI)
		switch(e) {
			MissingProviderException: fsa.generateFile(filename, e.compile(resource))
			Exception: fsa.generateFile(filename, e.compile(resource)) 
		}
	}

	def compile(MissingProviderException e, Resource resource) '''
		«resource.header»
		
		Something went wrong while generating code for the resource <<«e.name»>>.
		There might not exists an existing implementation for the cloud 
		provider selected: «e.provider.name».
		
		The available cloud providers for <<«e.name»>> are:
			«FOR c : e.availability»
				- «c.name»
			«ENDFOR»
	'''

	def compile(Exception e, Resource resource) '''
		«resource.header»
		
		An error occurred while generating code from DOML 
			«e.class.name»: «e.message»
				«FOR s : e.stackTrace.subList(0, 11)»
					at «s.className».«s.methodName» («s.fileName»:«s.lineNumber»)
				«ENDFOR»
				...
	'''

	// Compile main EClasses
	abstract def CharSequence compile(Resource resource) 
	abstract def CharSequence compile(CMetadata metadata) 
	abstract def CharSequence compile(CInputVariable variable) 
	abstract def CharSequence compile(CNodeTemplate node) 
	abstract def CharSequence compile(CNode node, TreeNodeTemplate tree) 
	abstract def CharSequence compile(CProperty property, CNodePropertyValue value, TreeNodeTemplate tree) 
	abstract def CharSequence compile(CNodeNestedProperty property, CProperty definition, TreeNodeTemplate tree)
	abstract def CharSequence compile(COutputVariable variable)
	
	// Compile Interfaces
	abstract def CharSequence compile(CNodeInterfaces interfaces, TreeNodeTemplate tree)
	abstract def CharSequence compile(CNodeInterface nodeInterface, TreeNodeTemplate tree)
	abstract def CharSequence compile(CConfigureDataVariable data, TreeNodeTemplate tree)
	
	// Compile Providers
	abstract def CharSequence compile(Map<CProvider, Integer> providers) 
	
	def getNode(CProperty property) {
		EcoreUtil2.getContainerOfType(property, CNodeType)
	}

	def getPropertyValue(CNodePropertyValue value, CProperty definition, TreeNodeTemplate tree) {
		switch value {
			CNodePropertyValueInline: this.getValueInline(value, tree)
			CNodeNestedProperty: value.compile(definition, tree)
		}
	}
	
	def getValueInline(CNodePropertyValueInline expr, TreeNodeTemplate tree) {
		switch expr {
			CNodePropertyValueInlineSingle: this.getValueInlineSingle(expr)
			CMultipleValueExpression: expr.compile(tree)
		}
	}

	def getValueInlineSingle(CNodePropertyValueInlineSingle expr) {
		switch expr {
			CValueExpression: this.getValueExpr(expr, false)
			CIntrinsicFunctions: this.getIntrinsicFunction(expr)
			default: ''
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

	def getIntrinsicFunction(CIntrinsicFunctions func) {
		switch func {
			CConcatValues: func.compile
			CNodeCrossRefGetInput: func.compile
			CNodeCrossRefGetAttribute: func.compile
			CNodeCrossRefGetValue: func.compile
		}
	}
	
	// Compile built-in functions 
	abstract def CharSequence compile(CConcatValues expr) 
	abstract def CharSequence compile(CNodeCrossRefGetInput expr) 
	abstract def CharSequence compile(CNodeCrossRefGetAttribute expr) 
	abstract def CharSequence compile(CNodeCrossRefGetValue expr)
	
	// Compile multiple values of properties 
	abstract def CharSequence compile(CMultipleValueExpression expr, TreeNodeTemplate tree)
	abstract def CharSequence compile(CMultipleNestedProperty property, CProperty definition, TreeNodeTemplate tree) 

	def getRoot(Resource r) {
		EcoreUtil2.getRootContainer(r.allContents.toIterable.get(0)) as DOMLModel
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
	
	def static TreeNodeTemplate getOrDefaultTreeTemplate(CNodeTemplate node, IResourceDescriptions descriptions) {
		if (OrchestratorGenerator.templates.containsKey(node.name))
			return OrchestratorGenerator.templates.get(node.name)
		
		val tree = new TreeNodeTemplate(
			node,
			descriptions
		)
		OrchestratorGenerator.templates.put(node.name, tree)
		return OrchestratorGenerator.templates.get(node.name)
	}
	
	def Iterable<TreeNodeTemplate> filter(Iterable<TreeNodeTemplate> trees, TreeNodeTemplate tree) {
		val filter = tree.root.provider
		
		if (filter === null)
			return trees 
			
		val filtered = trees.groupBy[ t |
			t.root.provider
		]
		
		if (filtered.get(filter) === null || filtered.get(filter).empty)
			throw new MissingProviderException(tree, filtered.keySet)
		else return filtered.get(filter)
	}
		
	def sort(Iterable<CNodeTemplate> iterable) {
		val list = iterable.toList
		Collections.sort(list, [ p1, p2 |
			if (p1.name !== null && p2.name !== null)
				p1.name.compareTo(p2.name)
			else 0
		]);
		return list
	}
	
}