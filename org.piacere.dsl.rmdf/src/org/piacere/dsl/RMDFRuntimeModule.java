/*
 * generated by Xtext 2.25.0
 */
package org.piacere.dsl;

import org.eclipse.xtext.scoping.IGlobalScopeProvider;
import org.eclipse.xtext.scoping.impl.ImportUriGlobalScopeProvider;

/**
 * Use this class to register components to be used at runtime / without the Equinox extension registry.
 */
public class RMDFRuntimeModule extends AbstractRMDFRuntimeModule {
	
	public Class<? extends IGlobalScopeProvider> bindIGlobalScopeProvider() {
		return ImportUriGlobalScopeProvider.class;
	}
	
}
