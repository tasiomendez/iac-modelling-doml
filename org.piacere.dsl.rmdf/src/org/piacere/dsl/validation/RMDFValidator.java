/*
 * generated by Xtext 2.25.0
 */
package org.piacere.dsl.validation;

import java.util.ArrayList;
import java.util.List;
import java.util.stream.Collectors;

import org.eclipse.emf.ecore.EObject;
import org.eclipse.emf.ecore.EReference;
import org.eclipse.xtext.EcoreUtil2;
import org.eclipse.xtext.validation.Check;
import org.piacere.dsl.rMDF.CMultipleNestedProperty;
import org.piacere.dsl.rMDF.CMultipleValueExpression;
import org.piacere.dsl.rMDF.CNode;
import org.piacere.dsl.rMDF.CNodeNestedProperty;
import org.piacere.dsl.rMDF.CNodeProperty;
import org.piacere.dsl.rMDF.CProperty;
import org.piacere.dsl.rMDF.RMDFPackage;

/**
 * This class contains custom validation rules. 
 *
 * See https://www.eclipse.org/Xtext/documentation/303_runtime_concepts.html#validation
 */
public class RMDFValidator extends AbstractRMDFValidator {

	//	public static final String INVALID_NAME = "invalidName";
	
	/**
	 * Get list of CProperty definitions objects given a container
	 * @param container
	 * @return the list of properties
	 */
	protected List<CProperty> getCProperties(EObject container) {
		return EcoreUtil2.getAllContentsOfType(container, CProperty.class);
	}

	/**
	 * Check the required properties of a CNode are satisfied.
	 * @param node
	 */
	@Check
	public final void checkNodeRequirements(CNode node) {

		List<CProperty> props = this.getCProperties(node.getType());
		List<CNodeProperty> properties = node.getProperties();

		this.checkNestedPropertyRequirements(props, properties, 
				RMDFPackage.Literals.CNODE__PROPERTIES);
	}

	/**
	 * Check the required properties of a NestedProperty which is defined
	 * by a datatype are satisfied.
	 * @param node
	 */
	@Check
	public final void checkNodeRequirements(CNodeNestedProperty node) {

		EObject container = this.getContainer(node);
		// Leave the multiple check to its own method
		if (EcoreUtil2.getContainerOfType(node, CMultipleValueExpression.class) != null)
			return;

		List<CProperty> props = this.getCProperties(container);
		List<CNodeProperty> properties = node.getProperties();

		this.checkNestedPropertyRequirements(props, properties,
				RMDFPackage.Literals.CNODE_NESTED_PROPERTY__PROPERTIES);
	}

	/**
	 * Check the required properties on a multiple nested property.
	 * @param node
	 */
	@Check
	public final void checkNodeRequirements(CMultipleNestedProperty node) {

		EObject container = this.getContainer(node);
		List<CProperty> props = this.getCProperties(container);
		List<CNodeProperty> properties = new ArrayList<CNodeProperty>();
		properties.add(node.getFirst());
		if (node.getRest() != null)
			properties.addAll(node.getRest().getProperties());

		this.checkNestedPropertyRequirements(props, properties,
				RMDFPackage.Literals.CMULTIPLE_NESTED_PROPERTY__FIRST);
	}

	/**
	 * Check if all the required properties are actually defined or not.
	 * 
	 * @param defined set of properties definition
	 * @param used set of properties used
	 * @param reference the reference where the error should be displayed
	 */
	protected void checkNestedPropertyRequirements(List<CProperty> defined, 
			List<CNodeProperty> used,
			EReference reference) {

		List<String> propertiesRequired = defined
				.stream()
				.filter(this::isRequired)
				.map((prop) -> prop.getName())
				.collect(Collectors.toList());

		List<String> currentProperties = used
				.stream()
				.map((prop) -> prop.getName().getName())
				.collect(Collectors.toList());

		if (!currentProperties.containsAll(propertiesRequired))
			error("Some required properties are missing: " + propertiesRequired.toString(), reference);
	}

	/**
	 * Get container of a given EObject. The container could be a nested property
	 * which is declared with a Datatype or a CNode.
	 * @param obj object
	 * @return the container object
	 */
	protected EObject getContainer(EObject obj) {

		// If the type is not declared return null 
		if (obj instanceof CNode) {
			CNode node = (CNode) obj;
			return node.getType();
		}

		CNodeProperty property = EcoreUtil2.getContainerOfType(obj, CNodeProperty.class);
		CProperty cproperty = (CProperty) property.eGet(RMDFPackage.Literals.CNODE_PROPERTY__NAME, false);

		// If it is a nested property return CProperty
		if (cproperty.getName() != null && cproperty.getProperty().getType().getDatatype() != null)
			return cproperty.getProperty().getType().getDatatype();
		// If it is not a nested property unroll
		else 
			return this.getContainer(obj.eContainer());
	}

	/**
	 * Return true if a property has the required attribute set to true
	 * or false otherwise
	 * @return true if required, false otherwise
	 */
	protected boolean isRequired(CProperty property) {
		return property.getProperty().getRequired() != null &&
				property.getProperty().getRequired().isValue();
	}

	/**
	 * Get dispatcher with the handlers for each terminal type
	 * @return handler
	 */
	protected RMDFHandler getDispatcher() {
		return new RMDFHandler(super::error, RMDFPackage.Literals.CNODE_PROPERTY__VALUE);
	}

	/**
	 * Check the property type is satisfied, even when using an input 
	 * variable.
	 * @param property
	 */
	@Check
	public final void checkPropertyType(CNodeProperty property) {

		EObject container = this.getContainer(property.eContainer());
		List<CProperty> props = this.getCProperties(container);

		CProperty rmdfProperty = props.stream()
				.filter(p -> p.getName().equals(property.getName().getName()))
				.findAny()
				.orElse(null);
		
		// Handler for property type
		RMDFHandler dispatcher = this.getDispatcher();
		dispatcher.handle(property.getValue(), rmdfProperty);

		// Check all values of the property when using multiple true
		if (property.getValue() instanceof CMultipleValueExpression)
			((CMultipleValueExpression) property.getValue()).getValues().forEach((v) -> {
				dispatcher.handle(v, rmdfProperty);
			});
	}

}
