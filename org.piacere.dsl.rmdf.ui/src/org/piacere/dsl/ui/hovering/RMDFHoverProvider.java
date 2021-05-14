package org.piacere.dsl.ui.hovering;

import org.eclipse.emf.ecore.EObject;
import org.eclipse.xtext.ui.editor.hover.html.DefaultEObjectHoverProvider;
import org.piacere.dsl.rMDF.CProperty;

public class RMDFHoverProvider extends DefaultEObjectHoverProvider {

	@Override
	protected String getHoverInfoAsHtml(EObject o) {
		if (o instanceof CProperty)
			return ((CProperty) o).getProperty().getDescription().getValue();
		return super.getHoverInfoAsHtml(o);
	}
	
}
