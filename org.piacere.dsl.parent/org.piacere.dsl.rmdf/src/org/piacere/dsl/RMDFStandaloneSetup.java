/*
 * generated by Xtext 2.25.0
 */
package org.piacere.dsl;


/**
 * Initialization support for running Xtext languages without Equinox extension registry.
 */
public class RMDFStandaloneSetup extends RMDFStandaloneSetupGenerated {

	public static void doSetup() {
		new RMDFStandaloneSetup().createInjectorAndDoEMFRegistration();
	}
}
