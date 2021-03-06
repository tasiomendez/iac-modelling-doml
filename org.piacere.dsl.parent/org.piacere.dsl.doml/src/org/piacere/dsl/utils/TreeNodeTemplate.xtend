package org.piacere.dsl.utils

import java.util.ArrayList
import java.util.Collections
import java.util.HashMap
import java.util.List
import java.util.Map
import java.util.Set
import java.util.function.Function
import java.util.stream.Collectors
import java.util.stream.StreamSupport
import org.eclipse.emf.ecore.EObject
import org.eclipse.xtext.EcoreUtil2
import org.eclipse.xtext.naming.QualifiedName
import org.eclipse.xtext.resource.IEObjectDescription
import org.eclipse.xtext.resource.IResourceDescriptions
import org.piacere.dsl.dOML.DOMLModel
import org.piacere.dsl.rMDF.CConfigureDataVariable
import org.piacere.dsl.rMDF.CMultipleNestedProperty
import org.piacere.dsl.rMDF.CNodeCapability
import org.piacere.dsl.rMDF.CNodeCrossRefGetValue
import org.piacere.dsl.rMDF.CNodeInterfaces
import org.piacere.dsl.rMDF.CNodeNestedProperty
import org.piacere.dsl.rMDF.CNodePropertyValue
import org.piacere.dsl.rMDF.CNodeRelationship
import org.piacere.dsl.rMDF.CNodeTemplate
import org.piacere.dsl.rMDF.CNodeType
import org.piacere.dsl.rMDF.CProperty
import org.piacere.dsl.rMDF.CProvider
import org.piacere.dsl.rMDF.CSTRING
import org.piacere.dsl.rMDF.RMDFModel
import org.piacere.dsl.rMDF.RMDFPackage

/**
 * This class is a Wrapper for the CNodeTemplate EObject which implements
 * some methods to make implementation easier.
 * It allows to access the hierarchy of RMDF files getting children and
 * properties in a recursive way.
 */
class TreeNodeTemplate {
	
	CNodeTemplate root
	QualifiedName alias
	List<TreeNodeTemplate> children
	Map<CProperty, CNodePropertyValue> properties
	Map<CProperty, CNodePropertyValue> overwrites
	
	Map<QualifiedName, CNodeRelationship> relationships = new HashMap<QualifiedName, CNodeRelationship>()
	List<CNodeCapability> capabilities = new ArrayList<CNodeCapability>()
		
	IResourceDescriptions descriptions
	
	new(CNodeTemplate root, IResourceDescriptions descriptions) {
		this.root = root
		this.alias = QualifiedName.create(root.name)
		this.descriptions = descriptions
		this.overwrites = Collections.emptyMap
			
		// Build properties and children attributes
		this.buildTree()
	}

	new(CNodeTemplate root, TreeNodeTemplate parent) {
		this(root, parent, "")
	}
	
	new(CNodeTemplate root, TreeNodeTemplate parent, String suffix) {
		this.root = root
		this.descriptions = parent.descriptions
		this.overwrites = parent.properties
		this.relationships.putAll(parent.relationships)

		// Add suffix to the name of the tree
		this.alias = parent.alias.append(root.name + suffix)

		// Build properties and children attributes
		this.buildTree()
	}
	
	/**
	 * Set the properties attribute and get all the children
	 */
	def private void buildTree() {
		// Update properties of root
		this.properties = this.setProperties
		
		// Update relationships
		if (this.root.template.relationships !== null)
			this.relationships.putAll(
				this.root.template.relationships.relationships.toMap([ r |
					this.alias.skipLast(1).append(r.value.name).append(r.name)
				], Function.identity())
			)
			
		// Update capabilities
		if (this.root.template.capabilities !== null)
			this.capabilities.addAll(this.root.template.capabilities.capabilities)
		
		// Update children
		this.children = new ArrayList<TreeNodeTemplate>()
		val childrenTemplates = this.childrenTemplates
		if (!childrenTemplates.empty)
			this.children.addAll(childrenTemplates)
			
		val childrenProvider = this.childrenProvider
		if (!childrenProvider.empty && childrenTemplates.empty) 
			this.children.addAll(childrenProvider)
		
	}

	/**
	 * Get root element
	 * @return root
	 */
	def CNodeTemplate getRoot() {
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
	 * Get name by joining alias segments
	 * @return name
	 */
	def String getName() {
		return this.alias.segments.join('_')
	}

	/**
	 * Get immediate children
	 * @return children
	 */
	def List<TreeNodeTemplate> getChildren() {
		return this.children
	}

	/**
	 * Get immediate children filter by cloud provider
	 * @return children
	 */
	def List<TreeNodeTemplate> getChildren(CProvider filter) {
		return children.filter [ c |
			c.root.provider == filter
		].toList
	}
	
	/**
	 * Get the relationships of root
	 * @return relationships
	 */
	def Map<QualifiedName, CNodeRelationship> getRelationships() {
		return this.relationships
	}
	
	/**
	 * Get the capabilities of root
	 * @return relationships
	 */
	def List<CNodeCapability> getCapabilities() {
		return this.capabilities
	}

	/**
	 * Get TreeNode leaves (those who does not have any children) which
	 * can be translated as the basic elements of DOML.
	 * @return leaves
	 */
	def List<TreeNodeTemplate> getLeaves() {
		val result = new ArrayList<TreeNodeTemplate>
		if (!this.isLeaf)
			this.children.forEach [ c |
				result.addAll(c.leaves)
			]
		else
			result.add(this)
		return result
	}

	/**
	 * Get TreeNode leaves filtering by type. There could be more than
	 * one node for a given type
	 * @return leaves
	 */
	def List<TreeNodeTemplate> getLeavesByType(CNodeType type) {
		return this.leaves.filter [ c |
			c.root.template.type.name === type.name
		].toList
	}

	/**
	 * A leaf is a node which does not have any children
	 * @return true if it is a leaf. Otherwise false
	 */
	def boolean isLeaf() {
		return this.children.empty
	}

	/**
	 * Check if a given NodeType is a child of the root
	 * @return true if it is a child. Otherwise false
	 */
	def boolean isChildren(CNodeType child) {
		if (this.isLeaf)
			return child.name === this.root.template.type?.name

		return this.children.stream.anyMatch [ c |
			c.isChildren(child)
		]
	}
	
	/**
	 * Check if a given TreeNodeTemplate is a child
	 * @return true if it is a child. Otherwise false
	 */
	def boolean isChildren(TreeNodeTemplate child) {
		if(!this.leaf)
			return this.isImmediateChild(child) || children.stream.anyMatch [ c |
				c.isChildren(child)
			]

		return false
	}
	
	/**
	 * Check if a given TreeNodeTemplate is an immediate child
	 * @return true if it is a child. Otherwise false
	 */
	def boolean isImmediateChild(TreeNodeTemplate child) {
		return this.children.contains(child)
	}

	/**
	 * Extract provider from the metadata given an EObject
	 * @return provider
	 */
	def private getProvider(EObject object) {
		val inneroot = EcoreUtil2::getRootContainer(object)
		return switch inneroot {
			RMDFModel: inneroot?.metadata?.provider
			DOMLModel: inneroot?.metadata?.provider
		}
	}

	/**
	 * Get children based on Cloud Provider. Some NodeTypes are cloud 
	 * independent and they do not have an implementation. This method
	 * search for the implementations of those nodes, looking for nodes
	 * which extend the cloud provider independent one.
	 * @return list of children
	 */
	def private List<TreeNodeTemplate> getChildrenProvider() {
		if (this.root === null || this.descriptions === null)
			return Collections.emptyList

		val extendables = this.getChildrenProviderFrom(this.root.template.type).flatMap[ n |
			this.getChildrenTemplatesFrom(n)
		]
				
		return extendables.toList
	}
	
	def private List<CNodeType> getChildrenProviderFrom(CNodeType type) {
		val Iterable<IEObjectDescription> elements = this.descriptions.getExportedObjectsByType(
			RMDFPackage.Literals::CNODE_TYPE)
		
		// This is a filter to take only one child for each provider
		val Map<CProvider, CNodeType> filter = new HashMap<CProvider, CNodeType>()
		
		val Set<CNodeType> extendables = StreamSupport.stream(elements.spliterator(), false).map [ node |
			EcoreUtil2::resolve(node.getEObjectOrProxy(), type) as CNodeType
		].filter [ node |
			if (!node.eIsProxy())
				return node?.data?.superType?.name == type.name
			return false
		].map[ node |
			val result = filter.putIfAbsent(node.provider, node)
			if (result === null)
				return node
			else return null
		].filter[ node |
			node !== null
		].flatMap [ node |
			val _children = this.getChildrenProviderFrom(node)
			val _node = new ArrayList<CNodeType>()
			_node.add(node)
			return if(_children.size > 0) _children.stream else _node.stream 
		].collect(Collectors.toSet())

		return extendables.toList
	}

	/**
	 * Get NodeTypes within the node_templates tag.
	 * @return list of children
	 */
	def private List<TreeNodeTemplate> getChildrenTemplates() {
		if (this.root === null)
			return Collections.emptyList

		return this.getChildrenTemplatesFrom(this.root.template.type)
	}
	
	def private List<TreeNodeTemplate> getChildrenTemplatesFrom(CNodeType type) {
		val nodeTemplates = EcoreUtil2::getAllContentsOfType(type, typeof(CNodeTemplate))
		if (!nodeTemplates.empty) {
			return nodeTemplates.flatMap[ t |
				val capability = this.capabilities.findFirst[ c |
					if (c.properties.targets !== null)
						c.properties.targets.targets.contains(t.template.type)
					else true
				]
				val children = new ArrayList<TreeNodeTemplate>()
				// If number of instances is greater than one, generate a number
				// of children equal to default_instances value
				if (capability !== null && capability.properties.instances.value > 1) {
					val instances = capability.properties.instances.value
					children.addAll(this.generateChildren(t, instances.intValue))
				} else {
					children.add(new TreeNodeTemplate(t, this))
				}
				return children
			].toList
		} else {
			return Collections.emptyList
		}
	}
	
	/**
	 * Generate X times TreeNodeTemplates from the given NodeTemplate
	 * @return list of children
	 */
	def List<TreeNodeTemplate> generateChildren(CNodeTemplate t, Integer times) {
		val children = new ArrayList<TreeNodeTemplate>()
		for (var i = 0 ; i < times ; i++) {
			children.add(new TreeNodeTemplate(t, this, '''_?i?'''))
		}
		return children
	}

	/**
	 * Get Map of properties and values from the root. The properties take
	 * into account the default values and overwrites done by the user.
	 * @return map of properties and properties values
	 */
	def Map<CProperty, CNodePropertyValue> getProperties() {
		return this.properties.filter [ prop, value |
			val type = EcoreUtil2.getContainerOfType(prop, CNodeType) as CNodeType
			return this.isChildren(type)
		]
	}

	/** 
	 * Set properties of the root object. At first the default values for each
	 * property is computed. Then, the defaults values are replaced by the
	 * properties set and new ones are added. Finally, the properties inherited
	 * from upper objects replace the old values.
	 * @return map of properties and properties values
	 */
	def private Map<CProperty, CNodePropertyValue> setProperties() {

		// Default values of properties
		val props = this.defaults

		// Properties of the root object
		this.root.template.properties.forEach [ p |
			props.put(p.name, p.value)
		]

		// Properties inherited from above
		props.putAll(this.overwrites)

		// Resolve cross values
		props.filter [ name, value |
			value instanceof CNodeCrossRefGetValue
		].forEach [ name, value |
			val crossref = value as CNodeCrossRefGetValue
			val reference = this.overwrites.get(crossref.crossvalue)
			val replacement = this.getOrDefaultValue(reference, crossref.crossvalue.property.^default)
			props.put(name, replacement)
		]

		return props
	}

	/**
	 * Resolve the get_value cross reference and replace the real value.
	 * @return map of properties and properties values
	 */
	def Map<CProperty, CNodePropertyValue> resolveProperties(EObject property, CProperty definition) {
		val props = switch (property) {
			CNodeNestedProperty:
				property.properties.toMap([name], [value])
			CMultipleNestedProperty: {
				val _props = new HashMap<CProperty, CNodePropertyValue>()
				_props.put(property.first.name, property.first.value)
				if (property.rest !== null)
					_props.putAll(property.rest.properties.toMap([name], [value]))
				_props
			}
			CConfigureDataVariable: {
				val _props = new HashMap<CProperty, CNodePropertyValue>()
				_props.put(null, property.value)
				_props
			}
			default:
				Collections.emptyMap
		}

		// Get default value if we are considering a datatype
		if (definition !== null)
			definition.property.type.datatype?.data?.properties?.filter [ p |
				p.property.^default !== null
			]?.forEach [ p |
				val replacement = this.getOrDefaultValue(props.get(p), p.property.^default)
				props.put(p, replacement)
			]

		// Resolve cross values
		props.filter [ name, value |
			value instanceof CNodeCrossRefGetValue
		].forEach [ name, value |
			val crossref = value as CNodeCrossRefGetValue
			val reference = this.properties.get(crossref.crossvalue)
			val replacement = this.getOrDefaultValue(reference, crossref.crossvalue.property.^default)
			props.put(name, replacement)
		]

		return props
	}

	/**
	 * Get new value or get the default. If there is not a default value nor a 
	 * new value, create error property value. Otherwise return the new value
	 * and it does not exists, return the default value
	 * @return the new property value
	 */
	def private CNodePropertyValue getOrDefaultValue(CNodePropertyValue newValue, CNodePropertyValue defaultValue) {
		if (newValue === null && defaultValue === null) {
			val error = EcoreUtil2.create(RMDFPackage.Literals::CSTRING) as CSTRING
			error.value = "## THIS PROPERTY IS MISSING ##"
			return error
		} else if (newValue === null) {
			return defaultValue
		} else {
			return newValue
		}
	}

	/**
	 * Get default values of node properties by checking the properties
	 * definition on RMDF
	 * @return map of properties and properties values
	 */
	def private Map<CProperty, CNodePropertyValue> getDefaults() {
		val defaults = this.root.template.type.data.properties.filter [ p |
			p.property.^default !== null
		].toMap(Function.identity(), [ p |
			p.property.^default as CNodePropertyValue
		])
		return defaults
	}

	/**
	 * Get the interfaces from the given object looping from root to the
	 * leaves.
	 * @return map of tree node and interfaces
	 */
	def Map<TreeNodeTemplate, CNodeInterfaces> getInterfaces() {
		val result = new HashMap<TreeNodeTemplate, CNodeInterfaces>()
		if (this.root.template.interfaces !== null)
			result.put(this, this.root.template.interfaces)

		this.children.forEach [ c |
			result.putAll(c.interfaces)
		]
		return result
	}

	override toString() {
		return this.root.toString
	}
	
}
	
	
	
	