/*
 * generated by Xtext 2.25.0
 */
package org.piacere.dsl.ui.labeling;

import org.eclipse.emf.edit.ui.provider.AdapterFactoryLabelProvider;
import org.piacere.dsl.dOML.CInputVariables;
import org.piacere.dsl.dOML.COutputVariables;
import org.piacere.dsl.rMDF.CNodeTemplates;

import com.google.inject.Inject;

/**
 * Provides labels for EObjects.
 * 
 * See https://www.eclipse.org/Xtext/documentation/310_eclipse_support.html#label-provider
 */
public class DOMLLabelProvider extends RMDFLabelProvider {

	@Inject
	public DOMLLabelProvider(AdapterFactoryLabelProvider delegate) {
		super(delegate);
	}

	// Labels and icons can be computed like this:
	
//	String text(Greeting ele) {
//		return "A greeting to " + ele.getName();
//	}
//
//	String image(Greeting ele) {
//		return "Greeting.gif";
//	}
	
	String text(CInputVariables ele) {
		return "input";
	}
	
	String text(CNodeTemplates ele) {
		return "node_templates";
	}
	
	String text(COutputVariables ele) {
		return "output";
	}
}
