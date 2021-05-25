package org.piacere.dsl.validation;

import org.eclipse.emf.ecore.EObject;
import org.eclipse.emf.ecore.EStructuralFeature;
import org.piacere.dsl.dOML.CInputVariable;
import org.piacere.dsl.dOML.CNodeCrossRefGetInput;
import org.piacere.dsl.rMDF.CProperty;

public class DOMLHandler extends RMDFHandler {

	public DOMLHandler(Validator function, EStructuralFeature feature) {
		super(function, feature);
	}

	@Override
	protected void handle(EObject property, CProperty definition) {
		if (property instanceof CNodeCrossRefGetInput)
			this.handle(CNodeCrossRefGetInput.class.cast(property), definition);
		else
			super.handle(property, definition);
	}

	protected void handle(CNodeCrossRefGetInput property, CProperty definition) {
		String type = this.getType(definition.getProperty().getType());
		CInputVariable input = ((CNodeCrossRefGetInput) property).getInput();
		if (!type.equals(input.getData().getType().getPredefined()))
			this.function.print(definition.getName() + " should be a " + type + ". "
					+ "Try changing input variable " + input.getName(),
					this.feature);
	}

}
