/*
 * generated by Xtext 2.25.0
 */
package org.piacere.dsl.validation;

import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

import org.eclipse.emf.ecore.EObject;
import org.eclipse.emf.ecore.EStructuralFeature;
import org.eclipse.xtext.EcoreUtil2;
import org.eclipse.xtext.validation.Check;
import org.piacere.dsl.dOML.CInputVariable;
import org.piacere.dsl.dOML.CNodeCrossRefGetInput;
import org.piacere.dsl.dOML.DOMLPackage;
import org.piacere.dsl.dOML.impl.CNodeCrossRefGetInputImpl;
import org.piacere.dsl.rMDF.CProperty;

/**
 * This class contains custom validation rules. 
 *
 * See https://www.eclipse.org/Xtext/documentation/303_runtime_concepts.html#validation
 */
public class DOMLValidator extends AbstractDOMLValidator {

	//	public static final String INVALID_NAME = "invalidName";

	/**
	 * Displays a warning if any input variable is not used on a given file.
	 * @param variable
	 */
	@Check
	public void checkUsabilityInputs(CInputVariable variable) {

		EObject root = EcoreUtil2.getRootContainer(variable, false);
		List<String> inputs = EcoreUtil2.getAllContentsOfType(root, CNodeCrossRefGetInput.class)
				.stream()
				.map((i) -> i.getInput().getName())
				.collect(Collectors.toList());
		if (!inputs.contains(variable.getName()))
			warning("Variable not used. May be removed.",
					variable, DOMLPackage.Literals.CINPUT_VARIABLE__NAME);
	}

	@Override
	protected Map<Class<? extends EObject>, Handler> getDispatcher() {
		Map<Class<? extends EObject>, Handler> dispatcher = super.getDispatcher();

		// Handler for input variables
		Handler cinputvariable = new Handler() {
			public void handle(EObject value, CProperty def, EStructuralFeature feature) {
				String type = this.getType(def.getProperty().getType());
				CInputVariable input = ((CNodeCrossRefGetInput) value).getInput();
				if (!type.equals(input.getData().getType().getPredefined()))
					error(def.getName() + " should be a " + type + ". "
							+ "Try changing input variable " + input.getName(),
							feature);
			}
		}; 
		
		dispatcher.put(CNodeCrossRefGetInputImpl.class, cinputvariable);
		
		return dispatcher;
	}

}
