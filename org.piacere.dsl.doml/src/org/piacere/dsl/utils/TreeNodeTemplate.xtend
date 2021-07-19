package org.piacere.dsl.utils

import java.util.ArrayList
import java.util.Collections
import java.util.List
import java.util.Map
import org.eclipse.emf.ecore.EObject
import org.eclipse.xtext.EcoreUtil2
import org.eclipse.xtext.naming.QualifiedName
import org.eclipse.xtext.resource.IResourceDescriptions
import org.piacere.dsl.dOML.DOMLModel
import org.piacere.dsl.rMDF.CNodeCrossRefGetValue
import org.piacere.dsl.rMDF.CNodePropertyValue
import org.piacere.dsl.rMDF.CNodeTemplate
import org.piacere.dsl.rMDF.CNodeType
import org.piacere.dsl.rMDF.CProperty
import org.piacere.dsl.rMDF.CProvider
import org.piacere.dsl.rMDF.CSTRING
import org.piacere.dsl.rMDF.RMDFPackage

class TreeNodeTemplate {

	CNodeTemplate root
	QualifiedName alias
	List<TreeNodeTemplate> children
	Map<CProperty, CNodePropertyValue> properties
	Map<CProperty, CNodePropertyValue> overwrites

	IResourceDescriptions descriptions
	
	new(CNodeTemplate root, Map<CProperty, CNodePropertyValue> overwrites) {
		this(root, QualifiedName.EMPTY, overwrites, null)
	}

	new(CNodeTemplate root, Map<CProperty, CNodePropertyValue> overwrites, IResourceDescriptions descriptions) {
		this(root, QualifiedName.EMPTY, overwrites, descriptions)
	}

	new(CNodeTemplate root, QualifiedName alias, Map<CProperty, CNodePropertyValue> overwrites, IResourceDescriptions descriptions) {
		this.root = root
		this.alias = alias
		this.descriptions = descriptions
		this.overwrites = overwrites
			
		// Update properties of root
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
				return new TreeNodeTemplate(t, qn, this.properties, this.descriptions)
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
	
	def Map<CProperty, CNodePropertyValue> getProperties() {
		return this.properties.filter [ prop, value |
			val type = EcoreUtil2.getContainerOfType(prop, CNodeType) as CNodeType
			return this.isChildren(type)
		]
	}
	
	def Map<CProperty, CNodePropertyValue> setProperties() {

		val props = this.defaults
		
		this.root.template.properties.forEach [ p |
			props.put(p.name, p.value)
		]
		
		props.putAll(this.overwrites)
		
		props.filter[ name, value |
			value instanceof CNodeCrossRefGetValue
		].forEach[ name, value | 			
			val reference = this.overwrites.get((value as CNodeCrossRefGetValue).crossvalue)
			val replacement = this.getOrDefaultValue(reference, value)
			props.put(name, replacement)
		]
		
		return props
	}
	
	def CNodePropertyValue getOrDefaultValue(CNodePropertyValue newValue, CNodePropertyValue crossref) {
		if (newValue === null && (crossref as CNodeCrossRefGetValue).crossvalue.property.^default !== null) {
			(crossref as CNodeCrossRefGetValue).crossvalue.property.^default
		} else if (newValue === null) {
			val error = EcoreUtil2.create(RMDFPackage.Literals::CSTRING) as CSTRING
			error.value = "## THIS PROPERTY IS MISSING ##"
			error
		} else {
			newValue
		}
	}
		
	def Map<CProperty, CNodePropertyValue> getDefaults() {
		val defaults = this.root.template.type.data.properties.filter[ p |
			p.property.^default !== null
		].toMap([ p | 
			p
		],[ p |
			p.property.^default as CNodePropertyValue
		])
		return defaults
	}

}
