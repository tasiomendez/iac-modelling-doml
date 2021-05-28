/*
 * generated by Xtext 2.25.0
 */
package org.piacere.dsl.validation;

import java.util.HashSet;
import java.util.List;
import java.util.Set;
import java.util.stream.Collectors;

import org.eclipse.emf.ecore.EObject;
import org.eclipse.xtext.EcoreUtil2;
import org.eclipse.xtext.validation.Check;
import org.piacere.dsl.dOML.CInputVariable;
import org.piacere.dsl.dOML.CNodeCrossRefGetInput;
import org.piacere.dsl.dOML.CNodeDefinition;
import org.piacere.dsl.dOML.CNodeProvider;
import org.piacere.dsl.dOML.DOMLPackage;
import org.piacere.dsl.rMDF.CProperty;
import org.piacere.dsl.rMDF.RMDFPackage;

/**
 * This class contains custom validation rules. 
 *
 * See https://www.eclipse.org/Xtext/documentation/303_runtime_concepts.html#validation
 */
public class DOMLValidator extends AbstractDOMLValidator {

	//	public static final String INVALID_NAME = "invalidName";
	
	@Override
	protected List<CProperty> getCProperties(EObject container) {
		if (container instanceof CNodeDefinition) {
			Set<CProperty> props = new HashSet<CProperty>();
			List<CNodeProvider> providers = EcoreUtil2.getAllContentsOfType(container, CNodeProvider.class);
			providers.forEach((p) -> {
				props.addAll(EcoreUtil2.getAllContentsOfType(p.getProvider(), CProperty.class));
			});
			return props.stream().collect(Collectors.toList());
		}
		return super.getCProperties(container);
	}
	
	@Override
	protected RMDFHandler getDispatcher() {
		return new DOMLHandler(super::error, RMDFPackage.Literals.CNODE_PROPERTY__VALUE);
	}
	
	/**
	 * Displays a warning if any input variable is not used on a given file.
	 * @param variable
	 */
	@Check
	public final void checkUsabilityInputs(CInputVariable variable) {

		EObject root = EcoreUtil2.getRootContainer(variable, false);
		List<String> inputs = EcoreUtil2.getAllContentsOfType(root, CNodeCrossRefGetInput.class)
				.stream()
				.map((i) -> i.getInput().getName())
				.collect(Collectors.toList());
		if (!inputs.contains(variable.getName()))
			warning("Variable not used. May be removed.",
					variable, DOMLPackage.Literals.CINPUT_VARIABLE__NAME);
	}

}
