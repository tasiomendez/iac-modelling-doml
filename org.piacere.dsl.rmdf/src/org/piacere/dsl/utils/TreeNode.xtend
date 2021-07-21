package org.piacere.dsl.utils

import java.util.ArrayList
import java.util.Collections
import java.util.HashMap
import java.util.List
import java.util.Map
import java.util.function.Function
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

/**
 * This class is a Wrapper for the CNodeType EObject which implements
 * some methods to make implementation easier.
 * It allows to access the hierarchy of RMDF files getting children and
 * properties in a recursive way.
 */
class TreeNode {

	CNodeType root
	QualifiedName alias
	List<TreeNode> children

	IResourceDescriptions descriptions

	new(CNodeType root) {
		this(root, QualifiedName.EMPTY, null)
	}

	new(CNodeType root, IResourceDescriptions descriptions) {
		this(root, QualifiedName.EMPTY, descriptions)
	}

	new(CNodeType root, QualifiedName alias, IResourceDescriptions descriptions) {
		this.root = root;
		this.alias = alias
		this.descriptions = descriptions
		this.children = new ArrayList<TreeNode>();

		val childrenProvider = this.childrenProvider
		if (!childrenProvider.empty)
			this.children.addAll(childrenProvider)
		val childrenTemplates = this.childrenTemplates
		if (!childrenTemplates.empty)
			this.children.addAll(childrenTemplates)
	}

	/**
	 * Get root element
	 * @return root
	 */
	def CNodeType getRoot() {
		return this.root
	}

	/**
	 * Get alias as QualifiedName
	 * @return qualified name
	 */
	def QualifiedName getAlias() {
		return this.alias
	}

	/**
	 * Get immediate children
	 * @return children
	 */
	def List<TreeNode> getChildren() {
		return this.children
	}

	/**
	 * Get immediate children filter by cloud provider
	 * @return children
	 */
	def List<TreeNode> getChildren(CProvider filter) {
		return children.filter [ c |
			c.root.provider == filter
		].toList
	}

	/**
	 * Get TreeNode leaves (those who does not have any children) which
	 * can be translated as the basic elements of DOML.
	 * @return leaves
	 */
	def List<TreeNode> getLeaves() {
		val result = new ArrayList<TreeNode>
		if (!this.isLeaf)
			this.children.forEach [ c |
				result.addAll(c.leaves)
			]
		else
			result.add(this)
		return result
	}

	/**
	 * A leaf is a node which does not have any children
	 * @return true if it is a leaf. Otherwise false
	 */
	def boolean isLeaf() {
		return this.children.empty
	}

	/**
	 * Extract provider from the metadata given an EObject
	 * @return provider
	 */
	def private CProvider getProvider(EObject object) {
		val inneroot = EcoreUtil2::getRootContainer(object) as RMDFModel
		return inneroot?.metadata?.provider
	}

	/**
	 * Get children based on Cloud Provider. Some NodeTypes are cloud 
	 * independent and they do not have an implementation. This method
	 * search for the implementations of those nodes, looking for nodes
	 * which extend the cloud provider independent one.
	 * @return list of children
	 */
	def private List<TreeNode> getChildrenProvider() {
		if (this.root === null || this.descriptions === null)
			return Collections.emptyList

		val Iterable<IEObjectDescription> elements = this.descriptions.getExportedObjectsByType(
			RMDFPackage.Literals::CNODE_TYPE)
		val List<TreeNode> extendables = StreamSupport.stream(elements.spliterator(), false).map [ node |
			EcoreUtil2::resolve(node.getEObjectOrProxy(), this.root) as CNodeType
		].filter [ node |
			if (!node.eIsProxy())
				return node?.data?.superType?.name == this.root.name
			return false
		].map [ node |
			return new TreeNode(node, this.alias, this.descriptions)
		].collect(Collectors.toList())
		return extendables
	}

	/**
	 * Get NodeTypes within the node_templates tag.
	 * @return list of children
	 */
	def private List<TreeNode> getChildrenTemplates() {
		if (this.root === null)
			return Collections.emptyList

		val nodeTemplates = EcoreUtil2::getAllContentsOfType(root, typeof(CNodeTemplate))
		if (!nodeTemplates.empty) {
			return nodeTemplates.map [ t |
				val QualifiedName qn = this.alias.append(t.name)
				return new TreeNode(t.template.type, qn, this.descriptions)
			].toList
		} else {
			return Collections.emptyList
		}
	}

	/**
	 * Get all the properties definition from the root to the leaves.
	 * The qualified name is composed by the name of the CNodeTemplates chained 
	 * and the name of the property.
	 * @return map of property and qualified name
	 */
	def Map<CProperty, QualifiedName> getAllCProperties() {
		return this.getAllCProperties(null)
	}

	/**
	 * Get all the properties definition from the root to the leaves, 
	 * filtering by cloud provider.
	 * The qualified name is composed by the name of the CNodeTemplates chained 
	 * and the name of the property.
	 * @return map of property and qualified name
	 */
	def Map<CProperty, QualifiedName> getAllCProperties(CProvider filter) {
		if (this.root === null || this.root.data === null)
			return Collections.emptyMap

		// Own properties
		val properties = this.getOwnProperties(filter)
		// SuperType properties
		properties.putAll(this.getSuperTypeProperties(filter))
		// Children properties
		properties.putAll(this.getChildrenProperties(filter))

		return properties
	}

	/**
	 * Get all the properties from the first level which takes the properties
	 * from the root node and the supertype in case it extends a node.
	 * @return map of property and qualified name
	 */
	def Map<CProperty, QualifiedName> getFirstLevelProperties() {
		return this.getFirstLevelProperties(null)
	}

	/**
	 * Get all the properties from the first level which takes the properties
	 * from the root node and the supertype in case it extends a node.
	 * @return map of property and qualified name
	 */
	def Map<CProperty, QualifiedName> getFirstLevelProperties(CProvider filter) {
		// Own properties
		val properties = this.getOwnProperties(filter)
		// SuperType properties
		properties.putAll(this.getSuperTypeProperties(filter))

		return properties
	}
	
	/**
	 * Get properties from the root node
	 * @return map of property and qualified name
	 */
	def private Map<CProperty, QualifiedName> getOwnProperties(CProvider filter) {
		return this.root.data.properties?.toMap(Function.identity, [ p |
			this.alias.append(p.name)
		])
	}
	
	/**
	 * Get properties from the supertype node in case the root extends
	 * a node type.
	 * @return map of property and qualified name
	 */
	def private Map<CProperty, QualifiedName> getSuperTypeProperties(CProvider filter) {
		if (this.root.data.superType !== null && !this.root.data.superType?.data.properties.empty)
			return this.root.data.superType?.data.properties.stream.collect(Collectors.toMap(Function.identity(), [ p |
				this.alias.append(p.name)
			]))
		else
			return Collections.emptyMap
	}
	
	/**
	 * Get properties from each children. It returns all properties from
	 * every children, from descendants to the leaves.
	 * @return map of property and qualified name
	 */
	def private Map<CProperty, QualifiedName> getChildrenProperties(CProvider filter) {
		val childs = if(filter === null) this.getChildren() else this.getChildren(filter)
		val properties = new HashMap<CProperty, QualifiedName>()
		childs.forEach [ c |
			properties.putAll(c.allCProperties)
		]
		return properties
	}

	override toString() {
		return this.root.toString
	}

}
