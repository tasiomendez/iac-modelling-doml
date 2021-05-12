package org.piacere.dsl.validation;

import org.eclipse.emf.ecore.EObject;
import org.eclipse.emf.ecore.EStructuralFeature;
import org.piacere.dsl.rMDF.CProperty;
import org.piacere.dsl.rMDF.CValueData;

/**
 * Declare an interface for the handlers to implement.
 * There will be only anonymous implementations of this interface.
 */
interface HandlerInterface {
	void handle(EObject value, CProperty property, EStructuralFeature feature);
	String getType(CValueData type);
}

/**
 * Handler implementation with general getType method
 */
public class Handler implements HandlerInterface {

	@Override
	public void handle(EObject value, CProperty property, EStructuralFeature feature) {
		return;
	}

	@Override
	public String getType(CValueData type) {
		return (type.getPredefined() == null) ? 
				type.getDatatype().getName() : type.getPredefined();
	}
	
}
