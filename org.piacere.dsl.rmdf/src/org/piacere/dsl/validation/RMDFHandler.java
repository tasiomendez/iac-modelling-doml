package org.piacere.dsl.validation;

import org.eclipse.emf.ecore.EObject;
import org.eclipse.emf.ecore.EStructuralFeature;
import org.piacere.dsl.rMDF.CBOOLEAN;
import org.piacere.dsl.rMDF.CFLOAT;
import org.piacere.dsl.rMDF.CMultipleValueExpression;
import org.piacere.dsl.rMDF.CNodeCrossRefGetValue;
import org.piacere.dsl.rMDF.CNodeNestedProperty;
import org.piacere.dsl.rMDF.CProperty;
import org.piacere.dsl.rMDF.CSIGNEDINT;
import org.piacere.dsl.rMDF.CSTRING;
import org.piacere.dsl.rMDF.CValueData;

/**
 * Handler implementation with general getType method
 */
public class RMDFHandler {

	protected EStructuralFeature feature;
	protected Validator function;

	public RMDFHandler(Validator function, EStructuralFeature feature) {
		this.function = function;
		this.feature = feature;
	}

	protected void handle(EObject property, CProperty definition) {
		if (property instanceof CSTRING)
			this.handle(CSTRING.class.cast(property), definition);
		else if (property instanceof CFLOAT)
			this.handle(CFLOAT.class.cast(property), definition);
		else if (property instanceof CSIGNEDINT)
			this.handle(CSIGNEDINT.class.cast(property), definition);
		else if (property instanceof CBOOLEAN)
			this.handle(CBOOLEAN.class.cast(property), definition);
		else if (property instanceof CNodeCrossRefGetValue)
			this.handle(CNodeCrossRefGetValue.class.cast(property), definition);
		else if (property instanceof CMultipleValueExpression)
			this.handle(CMultipleValueExpression.class.cast(property), definition);
		else if (property instanceof CNodeNestedProperty)
			this.handle(CNodeNestedProperty.class.cast(property), definition);
	}

	protected String getType(CValueData type) {
		return (type.getPredefined() == null) ? 
				type.getDatatype().getName() : type.getPredefined();
	}

	private void handle(CSTRING property, CProperty definition) {
		String type = this.getType(definition.getProperty().getType());
		if (!type.equals("String"))
			this.function.print(definition.getName() + " should be a " + type, this.feature);
	}

	private void handle(CFLOAT property, CProperty definition) {
		String type = this.getType(definition.getProperty().getType());
		if (!type.equals("Integer"))
			this.function.print(definition.getName() + " should be a " + type, this.feature);
	}

	private void handle(CSIGNEDINT property, CProperty definition) {
		String type = this.getType(definition.getProperty().getType());
		if (!type.equals("Integer"))
			this.function.print(definition.getName() + " should be a " + type, this.feature);
	}

	private void handle(CBOOLEAN property, CProperty definition) {
		String type = this.getType(definition.getProperty().getType());
		if (!type.equals("Boolean"))
			this.function.print(definition.getName() + " should be a " + type, this.feature);
	}

	private void handle(CNodeCrossRefGetValue property, CProperty definition) {
		String type = this.getType(definition.getProperty().getType());
		CProperty prop = ((CNodeCrossRefGetValue) property).getCrossvalue();
		if (!type.equals(prop.getProperty().getType().getPredefined()))
			this.function.print(definition.getName() + " should be a " + type + ". "
					+ "Try changing input variable " + prop.getName(),
					this.feature);
	}

	private void handle(CMultipleValueExpression property, CProperty definition) {
		if (definition.getProperty().getMultiple() == null || 
				!definition.getProperty().getMultiple().isValue())
			this.function.print(definition.getName() + " does not support multiple values", this.feature);
	}

	private void handle(CNodeNestedProperty property, CProperty definition) {
		if (definition.getProperty().getType().getDatatype() == null)
			this.function.print(definition.getName() + " should be a " + this.getType(definition.getProperty().getType()), 
					this.feature);
	}

	@FunctionalInterface
	protected interface Validator {
		void print(String string, EStructuralFeature feature);
	}
}
