package org.piacere.dsl.utils

import java.util.ArrayList
import java.util.Collections
import java.util.List
import java.util.Set
import java.util.function.Function
import org.eclipse.emf.ecore.EObject
import org.eclipse.xtext.EcoreUtil2
import org.eclipse.xtext.naming.QualifiedName
import org.eclipse.xtext.resource.IResourceDescriptions
import org.piacere.dsl.dOML.DOMLModel
import org.piacere.dsl.rMDF.CNodeProperty
import org.piacere.dsl.rMDF.CNodeTemplate
import org.piacere.dsl.rMDF.CNodeType
import org.piacere.dsl.rMDF.CProvider
import org.piacere.dsl.rMDF.RMDFPackage

class TreeNodeTemplate {

	CNodeTemplate root
	QualifiedName alias
	List<TreeNodeTemplate> children
	List<CNodeProperty> properties
	Set<CNodeProperty> overwrites

	IResourceDescriptions descriptions

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

		this.children = new ArrayList<TreeNodeTemplate>()
		val childrenTemplates = this.childrenTemplates
		if (!childrenTemplates.empty)
			this.children.addAll(childrenTemplates)
			
		// Update properties of root
		this.properties = this.setProperties
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
				return new TreeNodeTemplate(t, qn, this.overwrites, this.descriptions)
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
		return this.properties
	}
	
	def List<CNodeProperty> setProperties() {

		val props = this.defaults.toMap([ p |
			p.name
		], Function.identity())
		
		this.root.template.properties.forEach[ p | 
			props.put(p.name, p)
		]
		
		this.overwrites.filter [ p |
			val type = EcoreUtil2.getContainerOfType(p.name, CNodeType) as CNodeType
			return type?.name === this.root.template.type?.name
		].forEach[ p | 
			props.put(p.name, p)
		]
		
		val list = props.values.toList
		Collections.sort(list, [p1, p2 |
			if (p1.name.name !== null && p2.name.name !== null) 
				p1.name.name.compareTo(p2.name.name)
			else 0 
		]);
		return list
	}
	
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
