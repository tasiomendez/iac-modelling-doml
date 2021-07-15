package org.piacere.dsl.utils

import java.util.Collections
import java.util.HashSet
import java.util.Map
import java.util.Set
import java.util.stream.Collectors
import java.util.stream.StreamSupport
import org.eclipse.emf.ecore.EObject
import org.eclipse.xtext.EcoreUtil2
import org.eclipse.xtext.naming.QualifiedName
import org.eclipse.xtext.resource.IEObjectDescription
import org.eclipse.xtext.resource.IResourceDescriptions
import org.piacere.dsl.rMDF.CNodeTemplate
import org.piacere.dsl.rMDF.CNodeType
import org.piacere.dsl.rMDF.CProperty
import org.piacere.dsl.rMDF.CProvider
import org.piacere.dsl.rMDF.RMDFModel
import org.piacere.dsl.rMDF.RMDFPackage
import java.util.function.Function

class TreeNode {

	CNodeType root
	QualifiedName alias
	Set<TreeNode> children

	IResourceDescriptions descriptions

	new(CNodeType root, QualifiedName alias, IResourceDescriptions descriptions) {
		this.root = root;
		this.alias = alias
		this.descriptions = descriptions
		this.children = new HashSet<TreeNode>();

		val childrenProvider = this.childrenProvider
		if (!childrenProvider.empty)
			this.children.addAll(childrenProvider)
		val childrenTemplates = this.childrenTemplates
		if (!childrenTemplates.empty)
			this.children.addAll(childrenTemplates)
	}

	def CNodeType getRoot() {
		return this.root
	}

	def QualifiedName getAlias() {
		return this.alias
	}

	def Set<TreeNode> getChildren() {
		return this.children
	}

	def Set<TreeNode> getChildren(CProvider filter) {
		return children.filter [ c |
			c.root.provider == filter
		].toSet
	}

	def boolean isLeaf() {
		return this.children.empty
	}

	def private Set<TreeNode> getChildrenProvider() {
		if (this.root === null)
			return Collections.emptySet
		
		val Iterable<IEObjectDescription> elements = this.descriptions.getExportedObjectsByType(
			RMDFPackage.Literals::CNODE_TYPE)
		val Set<TreeNode> extendables = StreamSupport.stream(elements.spliterator(), false).map [ node |
			EcoreUtil2::resolve(node.getEObjectOrProxy(), this.root) as CNodeType
		].filter [ node |
			if (!node.eIsProxy())
				return node?.data?.superType?.name == this.root.name
			return false
		].map [ node |
			return new TreeNode(node, this.alias, this.descriptions)
		].collect(Collectors.toSet())
		return extendables
	}

	def private Set<TreeNode> getChildrenTemplates() {
		if (this.root === null)
			return Collections.emptySet
			
		val nodeTemplates = EcoreUtil2::getAllContentsOfType(root, typeof(CNodeTemplate))
		if (!nodeTemplates.empty) {
			return nodeTemplates.map [ t |
				val QualifiedName qn = this.alias.append(t.name)
				return new TreeNode(t.template.type, qn, this.descriptions)
			].toSet
		} else {
			return Collections.emptySet
		}
	}

	def private getProvider(EObject object) {
		val inneroot = EcoreUtil2::getRootContainer(object) as RMDFModel
		return inneroot?.metadata?.provider
	}

	def Map<CProperty, QualifiedName> getCProperties() {
		return this.getCProperties(null)
	}

	def Map<CProperty, QualifiedName> getCProperties(CProvider filter) {
		if (this.root === null || this.root.data === null)
			return Collections.emptyMap

		val properties = this.root.data.properties?.toMap(Function.identity, [ p |
			this.alias.append(p.name)
		])

		// SuperType properties
		if (this.root.data.superType !== null && !this.root.data.superType?.data.properties.empty)
			this.root.data.superType?.data.properties.forEach [ p |
				properties.put(p, this.alias.append(p.name))
			]

		// Children properties
		val childs = if(filter === null) this.getChildren() else this.getChildren(filter)
		childs.forEach [ c |
			properties.putAll(c.CProperties)
		]

		return properties
	}

	override toString() {
		return this.root.toString
	}

}
