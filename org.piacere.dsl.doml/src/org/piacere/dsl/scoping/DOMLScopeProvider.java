/*
 * generated by Xtext 2.25.0
 */
package org.piacere.dsl.scoping;

import org.eclipse.emf.ecore.EObject;
import org.eclipse.emf.ecore.EReference;
import org.eclipse.xtext.resource.IResourceDescription;
import org.eclipse.xtext.scoping.IScope;
import org.eclipse.xtext.scoping.IScopeProvider;
import org.eclipse.xtext.scoping.impl.FilteringScope;
import org.piacere.dsl.dOML.CNodeDefinition;
import org.piacere.dsl.dOML.DOMLPackage;
import org.piacere.dsl.rMDF.CNodeType;

import com.google.inject.Inject;

/**
 * This class contains custom scoping description.
 * 
 * See https://www.eclipse.org/Xtext/documentation/303_runtime_concepts.html#scoping
 * on how and when to use it.
 */
public class DOMLScopeProvider extends AbstractDOMLScopeProvider {

	@Inject
	IResourceDescription.Manager mgr;
		
	@Override
	public IScope getScope(EObject context, EReference reference) {
		
		IScopeProvider provider = super.getDelegate();
		
		if (reference == DOMLPackage.Literals.CNODE_PROVIDER__PROVIDER) {
			return provider.getScope(context, reference);						
		}

		if (reference == DOMLPackage.Literals.CNODE__CTYPE) {
			return new FilteringScope(provider.getScope(context, reference), (s) -> {
				EObject obj = s.getEObjectOrProxy();
				return (obj instanceof CNodeType || obj instanceof CNodeDefinition);
			});
		}
		
		return super.getScope(context, reference);
	}

}
