package org.piacere.dsl.utils;

import java.util.Collections;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.function.Function;
import java.util.stream.Collectors;

import org.eclipse.emf.ecore.EObject;
import org.eclipse.xtext.EcoreUtil2;
import org.eclipse.xtext.naming.QualifiedName;
import org.piacere.dsl.rMDF.CDataType;
import org.piacere.dsl.rMDF.CNode;
import org.piacere.dsl.rMDF.CNodeProperty;
import org.piacere.dsl.rMDF.CNodeTemplate;
import org.piacere.dsl.rMDF.CNodeType;
import org.piacere.dsl.rMDF.CProperty;
import org.piacere.dsl.rMDF.RMDFPackage;

public class Helper {

	/**
	 * Get container of a given EObject. The container could be a nested property
	 * which is declared with a Datatype or a CNode.
	 * @param obj
	 * @return the container object (CNodeType || CDataType)
	 */
	public static EObject getContainer(EObject obj) {

		// If the type is not declared return null 
		if (obj instanceof CNode) {
			CNode node = (CNode) obj;
			return node.getType();
		}

		CNodeProperty property = EcoreUtil2.getContainerOfType(obj, CNodeProperty.class);
		CProperty cproperty = (CProperty) property.eGet(RMDFPackage.Literals.CNODE_PROPERTY__NAME, false);

		// If it is a nested property return DataType
		if (cproperty.getName() != null && cproperty.getProperty().getType().getDatatype() != null)
			return cproperty.getProperty().getType().getDatatype();
		// If it is not a nested property unroll
		else 
			return Helper.getContainer(obj.eContainer());
	}

	/**
	 * Get all CProperty which hangs from a given container
	 * @param container
	 * @param deep get deeper properties
	 * @return list of CProperty
	 */
	public static Map<CProperty, QualifiedName> getAllCProperty(EObject obj, Boolean deep) {
		EObject container = Helper.getContainer(obj);
		// If it is a nested property return CProperty of DataType
		if (container instanceof CDataType && !container.eIsProxy()) {
			return Helper.getCPropertyFromDataType((CDataType) container);
			// If it is not a nested property return CProperty of NodeType
		} else if (container instanceof CNodeType && !container.eIsProxy()) {
			Map<CProperty, QualifiedName> properties = Helper.getCPropertyFromNodeType((CNodeType) container, null);
			if (deep)
				properties.putAll(Helper.getCPropertyFromNodeTypeNodeTemplates((CNodeType) container, null));
			return properties;
		} else { 
			return Collections.emptyMap();
		}
	}

	/**
	 * Get all CProperty which hangs from a nested CProperty
	 * @param container
	 * @return list of CProperty
	 */
	public static Map<CProperty, QualifiedName> getCPropertyFromDataType(CDataType container) {
		Map<CProperty, QualifiedName> properties = EcoreUtil2.getAllContentsOfType(container, CProperty.class)
				.stream()
				.collect(Collectors.toMap(Function.identity(), (p) -> {
					return QualifiedName.create(p.getName());
				}));
		return properties;
	}

	/**
	 * Get all CProperty which hangs from a CNodeType including inheritance from super instance
	 * @param container
	 * @return list of CProperty
	 */
	public static Map<CProperty, QualifiedName> getCPropertyFromNodeType(CNodeType container, QualifiedName upper) {
		if (container == null)
			return Collections.emptyMap();

		Map<CProperty, QualifiedName> properties = EcoreUtil2.getAllContentsOfType(container, CProperty.class)
				.stream()
				.collect(Collectors.toMap(Function.identity(), (p) -> {
					if (upper == null)
						return QualifiedName.create(p.getName());
					return upper.append(p.getName());
				}));
		// Super CProperty
		CNodeType supertype = container.getData().getSuperType();
		if (supertype != null)
			properties.putAll(Helper.getCPropertyFromNodeType(supertype, upper));

		return properties;
	}

	/**
	 * Get all CProperty of the nodes in NodeTemplates to provides overrides
	 * 
	 * @param container
	 * @param upper qualified name
	 * @return list of CProperty
	 */
	public static Map<CProperty, QualifiedName> getCPropertyFromNodeTypeNodeTemplates(CNodeType container, QualifiedName upper) {
		Map<CProperty, QualifiedName> properties = new HashMap<CProperty, QualifiedName>();
		List<CNodeTemplate> nodes = EcoreUtil2.getAllContentsOfType(container, CNodeTemplate.class);
		nodes.forEach((n) -> {
			QualifiedName acc;
			if (upper == null)
				acc = QualifiedName.create(n.getName());
			else acc = upper.append(n.getName());

			if (n.getTemplate().getType() != null)
				properties.putAll(Helper.getCPropertyFromNodeType(n.getTemplate().getType(), acc));
		});
		return properties;
	}
}
