package org.piacere.dsl.ui.hovering;

import org.eclipse.emf.ecore.EObject;
import org.eclipse.xtext.naming.IQualifiedNameProvider;
import org.eclipse.xtext.naming.QualifiedName;
import org.eclipse.xtext.ui.editor.hover.html.DefaultEObjectHoverProvider;

import com.google.inject.Inject;

public class DOMLHoverProvider extends DefaultEObjectHoverProvider {

	@Inject
	IQualifiedNameProvider qnp;

	@Override
	protected String getHoverInfoAsHtml(EObject o) {
		return super.getHoverInfoAsHtml(o);
	}
	
	protected String getHeader(EObject o) {
		QualifiedName qn = qnp.getFullyQualifiedName(o);
		return o.eClass().getName() + ((qn.getSegmentCount() > 0) ? " <b>"+qn.toString()+"</b>" : "");
	}
	
}
