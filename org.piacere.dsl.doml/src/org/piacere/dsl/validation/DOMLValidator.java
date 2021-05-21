/*
 * generated by Xtext 2.25.0
 */
package org.piacere.dsl.validation;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Stack;
import java.util.function.Function;
import java.util.stream.Collectors;
import java.util.stream.Stream;

import org.eclipse.emf.ecore.EObject;
import org.eclipse.emf.ecore.EReference;
import org.eclipse.emf.ecore.EStructuralFeature;
import org.eclipse.xtext.EcoreUtil2;
import org.eclipse.xtext.validation.Check;
import org.piacere.dsl.dOML.CInputVariable;
import org.piacere.dsl.dOML.CMultipleNestedProperty;
import org.piacere.dsl.dOML.CMultipleValueExpression;
import org.piacere.dsl.dOML.CNode;
import org.piacere.dsl.dOML.CNodeNestedProperty;
import org.piacere.dsl.dOML.CNodeProperty;
import org.piacere.dsl.dOML.CRefInputVariable;
import org.piacere.dsl.dOML.DOMLPackage;
import org.piacere.dsl.dOML.impl.CBOOLEANImpl;
import org.piacere.dsl.dOML.impl.CFLOATImpl;
import org.piacere.dsl.dOML.impl.CMultipleValueExpressionImpl;
import org.piacere.dsl.dOML.impl.CNodeNestedPropertyImpl;
import org.piacere.dsl.dOML.impl.CRefInputVariableImpl;
import org.piacere.dsl.dOML.impl.CSIGNEDINTImpl;
import org.piacere.dsl.dOML.impl.CSTRINGImpl;
import org.piacere.dsl.rMDF.CNodeType;
import org.piacere.dsl.rMDF.CProperty;

/**
 * This class contains custom validation rules. 
 *
 * See https://www.eclipse.org/Xtext/documentation/303_runtime_concepts.html#validation
 */
public class DOMLValidator extends AbstractDOMLValidator {

	//	public static final String INVALID_NAME = "invalidName";

	// TODO:
	// - Check the required properties (OK)
	// - Check if property is in rmdf (OK) -> Warning!!
	// - Check the type of the property value (OK) 
	// - Check the type of the property when using other data types (OK)
	// - Check if it accepts multiple values (OK)
	// - Show description of the property and default value (OK)

	@Check
	public void checkNodeRequirements(CNode node) {
		
		List<CProperty> props = EcoreUtil2.getAllContentsOfType(node.getType(), CProperty.class);
		List<CNodeProperty> properties = node.getProperties();
		
		this.checkNestedPropertyRequirements(props, properties, 
				DOMLPackage.Literals.CNODE__PROPERTIES);
	}
	
	@Check
	public void checkNodeRequirements(CNodeNestedProperty node) {
		
		EObject container = this.getContainer(node);
		// Leave the multiple check to its own method
		if (EcoreUtil2.getContainerOfType(node, CMultipleValueExpression.class) != null)
			return;
		
		List<CProperty> props = EcoreUtil2.getAllContentsOfType(container, CProperty.class);
		List<CNodeProperty> properties = node.getProperties();
		
		this.checkNestedPropertyRequirements(props, properties,
				DOMLPackage.Literals.CNODE_NESTED_PROPERTY__PROPERTIES);
	}
	
	@Check
	public void checkNodeRequirements(CMultipleNestedProperty node) {

		EObject container = this.getContainer(node);
		List<CProperty> props = EcoreUtil2.getAllContentsOfType(container, CProperty.class);
		List<CNodeProperty> properties = new ArrayList<CNodeProperty>();
		properties.add(node.getFirst());
		if (node.getRest() != null)
			properties.addAll(node.getRest().getProperties());
		
		this.checkNestedPropertyRequirements(props, properties,
				DOMLPackage.Literals.CMULTIPLE_NESTED_PROPERTY__FIRST);
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
	 * @param obj
	 * @return the container object
	 */
	protected EObject getContainer(EObject obj) {

		// If the type is not declared return null 
		if (obj instanceof CNode) {
			CNode node = (CNode) obj;
			if (node.getType() == null)
				return null;
			else 
				return node.getType();
		}

		CNodeProperty property = EcoreUtil2.getContainerOfType(obj, CNodeProperty.class);
		CProperty cproperty = (CProperty) property.eGet(DOMLPackage.Literals.CNODE_PROPERTY__NAME, false);

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

//	/**
//	 * Get a map of properties in RMDF for a given property which can 
//	 * be nested and not be on the root
//	 * @param object
//	 * @return map of <String, CPropertyBody>
//	 */
//	private Map<String, CProperty> getMappedPropertiesRMDF (EObject object) {
//		Stack<CNodeProperty> stack = new Stack<CNodeProperty>();
//		EObject parent = object;
//		while (!(parent instanceof CNode)) {
//			if (parent instanceof CNodeProperty)
//				stack.push((CNodeProperty) parent);
//			parent = parent.eContainer();
//		}
//
//		// Get main CNode properties
//		CNode node = EcoreUtil2.getContainerOfType(object, CNode.class);
//		Map<String, CProperty> properties = node.getType()
//				.getData()
//				.getProperties()
//				.stream()
//				.collect(Collectors.toMap(
//						CProperty::getName, Function.identity()
//						));
//		
//		// 	First level CNodeProperty which is the last one in enter the stack
//		CNodeProperty element = stack.pop();
//		while(!stack.isEmpty()) {
//			CProperty prop = properties.get(element.getName().getName());
//			// Nested objects has always datatypes declared
//			properties = prop.getProperty().getType().getDatatype()
//					.getData()
//					.getProperties()
//					.stream()
//					.collect(Collectors.toMap(CProperty::getName, Function.identity()));
//			element = stack.pop();
//		}
//		return properties;
//	}
//
//	@Check
//	public void checkPropertyType(CNodeProperty property) {
//
//		Map<String, CProperty> properties = this.getMappedPropertiesRMDF(property);
//		CNode node = EcoreUtil2.getContainerOfType(property, CNode.class);
//
//		CProperty rmdfProperty = properties.get(property.getName().getName());
//		if (rmdfProperty == null)
//			warning("Property not defined in RMDF model for " + node.getType().getName(),
//					property, DOMLPackage.Literals.CNODE_PROPERTY__NAME);
//
//		Handler handler = this.getDispatcher().get(property.getValue().getClass());
//		handler.handle(property.getValue(), rmdfProperty, DOMLPackage.Literals.CNODE_PROPERTY__VALUE);
//
//		// Check all values of the property when using multiple true
//		if (property.getValue() instanceof CMultipleValueExpression)
//			((CMultipleValueExpression) property.getValue()).getValues().forEach((v) -> {
//				Handler h = this.getDispatcher().get(v.getClass());
//				h.handle(v, rmdfProperty, DOMLPackage.Literals.CNODE_PROPERTY__VALUE);
//			});
//	}
//	
//	private <T> T getNodeType(EObject o, Class<T> type) {
//		try {
//			return type.cast(o);
//		} catch (Exception e) {
//			return null;
//		}
//	}
//
//	/**
//	 * Builds a dispatcher based on a HashMap where each class type 
//	 * has a handler in order to validate the value types
//	 * @return hash map dispatcher
//	 */
//	private Map<Class<? extends EObject>, Handler> getDispatcher() {	
//		Map<Class<? extends EObject>, Handler> dispatcher = new HashMap<Class<? extends EObject>, Handler>();
//
//		// Handler for strings
//		Handler cstring = new Handler() {
//			public void handle(EObject value, CProperty def, EStructuralFeature feature) {
//				String type = this.getType(def.getProperty().getType());
//				if (!type.equals("String"))
//					error(def.getName() + " should be a " + type, feature);
//			}
//		};
//
//		// Handler for integer and floats
//		Handler cinteger = new Handler() {
//			public void handle(EObject value, CProperty def, EStructuralFeature feature) {
//				String type = this.getType(def.getProperty().getType());
//				if (!type.equals("Integer"))
//					error(def.getName() + " should be a " + type, feature);
//			}
//		}; 
//
//		// Handler for booleans (true and false)
//		Handler cboolean = new Handler() {
//			public void handle(EObject value, CProperty def, EStructuralFeature feature) {
//				String type = this.getType(def.getProperty().getType());
//				if (!type.equals("Boolean"))
//					error(def.getName() + " should be a " + type, feature);
//			}
//		}; 
//
//		// Handler for input variables
//		Handler cinputvariable = new Handler() {
//			public void handle(EObject value, CProperty def, EStructuralFeature feature) {
//				String type = this.getType(def.getProperty().getType());
//				CInputVariable input = ((CRefInputVariable) value).getInput();
//				if (!type.equals(input.getData().getType().getPredefined()))
//					error(def.getName() + " should be a " + type + ". "
//							+ "Try changing input variable " + input.getName(),
//							feature);
//			}
//		}; 
//
//		// Handler multiple value expressions
//		// The handler for the type of each value is made recursively
//		Handler cmultiple = new Handler() {
//			public void handle(EObject value, CProperty def, EStructuralFeature feature) {
//				if (def.getProperty().getMultiple() == null || !def.getProperty().getMultiple().isValue())
//					error(def.getName() + " does not support multiple values", feature);
//			}
//		};
//
//		// Handler nested datatypes
//		Handler cnested = new Handler() {
//			public void handle(EObject value, CProperty def, EStructuralFeature feature) {
//				if (def.getProperty().getType().getDatatype() == null)
//					error(def.getName() + " should be a " + this.getType(def.getProperty().getType()), feature);
//			}
//		};
//
//		dispatcher.put(CSTRINGImpl.class, cstring);
//		dispatcher.put(CFLOATImpl.class, cinteger);
//		dispatcher.put(CSIGNEDINTImpl.class, cinteger);
//		dispatcher.put(CBOOLEANImpl.class, cboolean);
//		dispatcher.put(CRefInputVariableImpl.class, cinputvariable);
//		dispatcher.put(CMultipleValueExpressionImpl.class, cmultiple);
//		dispatcher.put(CNodeNestedPropertyImpl.class, cnested);
//
//		return dispatcher;
//	}
//	
//	@Check
//	public void checkUsabilityInputs(CInputVariable variable) {
//		
//		EObject root = EcoreUtil2.getRootContainer(variable, false);
//		List<String> inputs = EcoreUtil2.getAllContentsOfType(root, CRefInputVariable.class)
//				.stream()
//				.map((i) -> i.getInput().getName())
//				.collect(Collectors.toList());
//		if (!inputs.contains(variable.getName()))
//			warning("Variable not used. May be removed.",
//					variable, DOMLPackage.Literals.CINPUT_VARIABLE__NAME);
//		
//	}

}
