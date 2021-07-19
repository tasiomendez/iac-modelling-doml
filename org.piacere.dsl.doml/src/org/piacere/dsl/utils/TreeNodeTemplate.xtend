package org.piacere.dsl.utils

import java.util.ArrayList
import java.util.Collections
import java.util.HashMap
import java.util.List
import java.util.Map
import java.util.Set
import java.util.function.Function
import org.eclipse.emf.ecore.EObject
import org.eclipse.xtext.EcoreUtil2
import org.eclipse.xtext.naming.QualifiedName
import org.eclipse.xtext.resource.IResourceDescriptions
import org.piacere.dsl.dOML.DOMLModel
import org.piacere.dsl.rMDF.CNodeCrossRefGetValue
import org.piacere.dsl.rMDF.CNodeProperty
import org.piacere.dsl.rMDF.CNodePropertyValue
import org.piacere.dsl.rMDF.CNodeTemplate
import org.piacere.dsl.rMDF.CNodeType
import org.piacere.dsl.rMDF.CProvider
import org.piacere.dsl.rMDF.CSTRING
import org.piacere.dsl.rMDF.RMDFPackage

class TreeNodeTemplate {

	CNodeTemplate root
	QualifiedName alias
	List<TreeNodeTemplate> children
	List<CNodeProperty> properties
	Set<CNodeProperty> overwrites

	IResourceDescriptions descriptions
	
	Map<CNodeProperty, CNodePropertyValue> getValuesExpr

	new(CNodeTemplate root, Set<CNodeProperty> overwrites) {
		this(root, QualifiedName.EMPTY, overwrites, null)
	}

	new(CNodeTemplate root, Set<CNodeProperty> overwrites, IResourceDescriptions descriptions) {
		this(root, QualifiedName.EMPTY, overwrites, descriptions)
	}

	new(CNodeTemplate root, QualifiedName alias, Set<CNodeProperty> overwrites, IResourceDescriptions descriptions) {
		this.root = root
		this.alias = alias
		this.descriptions = descriptions
		this.overwrites = overwrites
			
		// Update properties of root
		this.getValuesExpr = new HashMap<CNodeProperty, CNodePropertyValue>()
		this.properties = this.setProperties

		this.children = new ArrayList<TreeNodeTemplate>()
		val childrenTemplates = this.childrenTemplates
		if (!childrenTemplates.empty)
			this.children.addAll(childrenTemplates)
	}

	def CNodeTemplate getRoot() {
		return this.root
	}

	def QualifiedName getAlias() {
		return this.alias
	}

	def List<TreeNodeTemplate> getChildren() {
		return this.children
	}

	def List<TreeNodeTemplate> getChildren(CProvider filter) {
		return children.filter [ c |
			c.root.provider == filter
		].toList
	}

	def boolean isLeaf() {
		return this.children.empty
	}
	
	def boolean isChildren(CNodeType child) {
		if (this.isLeaf)
			return child.name === this.root.template.type?.name
		
		return this.children.stream.anyMatch[ c |
			c.isChildren(child)
		]
	}

	def private getProvider(EObject object) {
		val inneroot = EcoreUtil2::getRootContainer(object) as DOMLModel
		return inneroot?.metadata?.provider
	}

	def private List<TreeNodeTemplate> getChildrenTemplates() {
		if (this.root === null)
			return Collections.emptyList

		val nodeTemplates = EcoreUtil2::getAllContentsOfType(this.root.template.type, typeof(CNodeTemplate))
		if (!nodeTemplates.empty) {
			return nodeTemplates.map [ t |
				val QualifiedName qn = this.alias.append(t.name)
				return new TreeNodeTemplate(t, qn, this.properties.toSet, this.descriptions)
			].toList
		} else {
			return Collections.emptyList
		}
	}
	
	def List<TreeNodeTemplate> getTemplates() {
		val result = new ArrayList<TreeNodeTemplate>
		if (!this.isLeaf)
			this.children.forEach[ c |
				result.addAll(c.templates)
			]
		else
			result.add(this)
		return result
	}
		
	def String getName() {
		this.alias.segments.join('_')
	}

	override toString() {
		return this.root.toString
	}
	
	def List<CNodeProperty> getProperties() {
		return this.properties.filter [ p |
			val type = EcoreUtil2.getContainerOfType(p.name, CNodeType) as CNodeType
			return this.isChildren(type)
		].toList
	}
	
	def List<CNodeProperty> setProperties() {

		val props = this.defaults.toMap([ p |
			p.name
		], Function.identity())
		
		this.root.template.properties.forEach [ p |
			props.put(p.name, p)
		]
		
		this.overwrites.forEach[ p | 
			props.put(p.name, p)
		]
		
		props.filter[ name, p |
			p.value instanceof CNodeCrossRefGetValue
		].forEach[ name, p | 
//			val property = EcoreUtil2.create(RMDFPackage.Literals::CNODE_PROPERTY) as CNodeProperty
//			property.name = p.name
//			val reference = this.overwrites.findFirst [ prop |
//				(p.value as CNodeCrossRefGetValue).crossvalue === prop.name
//			]
//
//			property.value = this.copyValue(reference, p.value)
//			props.put(property.name, property)
			
			val reference = this.overwrites.findFirst [ prop |
				(p.value as CNodeCrossRefGetValue).crossvalue === prop.name
			]
			val value = this.getPropertyValue(reference, p.value)
			this.getValuesExpr.put(p, value)
		]
		
		val list = props.values.toList
		Collections.sort(list, [p1, p2 |
			if (p1.name.name !== null && p2.name.name !== null) 
				p1.name.name.compareTo(p2.name.name)
			else 0 
		]);
		return list
	}
	
	def CNodePropertyValue getPropertyValue(CNodeProperty reference, CNodePropertyValue value) {
		if (reference === null && (value as CNodeCrossRefGetValue).crossvalue.property.^default !== null) {
			(value as CNodeCrossRefGetValue).crossvalue.property.^default
		} else if (reference === null) {
			val error = EcoreUtil2.create(RMDFPackage.Literals::CSTRING) as CSTRING
			error.value = "## THIS PROPERTY IS MISSING ##"
			error
		} else {
			reference.value
		}
	}
	
	def Map<CNodeProperty, CNodePropertyValue> getAllValuesExpr() {
		val result = new HashMap<CNodeProperty, CNodePropertyValue>
		if (!this.isLeaf)
			this.children.forEach[ c |
				result.putAll(c.allValuesExpr)
			]
		else
			result.putAll(this.getValuesExpr)
		return result
	}

//	def CNodePropertyValue searchGetValue(CNodeCrossRefGetValue value) {
//		val reference = this.overwrites.findFirst [ prop |
//			value.crossvalue === prop.name
//		]
//		
//		if (reference === null && (value as CNodeCrossRefGetValue).crossvalue.property.^default !== null) {
//			return (value as CNodeCrossRefGetValue).crossvalue.property.^default
//		} else if (reference === null) {
//			val error = EcoreUtil2.create(RMDFPackage.Literals::CSTRING) as CSTRING
//			error.value = "## THIS PROPERTY IS MISSING ##"
//			return error
//		} else {
//			return reference.value
//		}
//	}
	
	def List<CNodeProperty> getDefaults() {
		val defaults = this.root.template.type.data.properties.filter[ p |
			p.property.^default !== null
		].map[ p |
			val node = EcoreUtil2.create(RMDFPackage.Literals::CNODE_PROPERTY) as CNodeProperty
			node.name = p
			node.value = p.property.^default
			return node
		].toList
		return defaults
	}

}
