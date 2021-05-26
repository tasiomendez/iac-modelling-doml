package org.piacere.dsl.ui.hovering;

import java.util.List;

import org.eclipse.emf.ecore.EObject;
import org.eclipse.xtext.naming.IQualifiedNameProvider;
import org.eclipse.xtext.naming.QualifiedName;
import org.eclipse.xtext.ui.editor.hover.html.DefaultEObjectHoverProvider;
import org.piacere.dsl.dOML.CNodeDefinition;
import org.piacere.dsl.dOML.CNodeProvider;

import com.google.inject.Inject;

public class DOMLHoverProvider extends DefaultEObjectHoverProvider {

	@Inject
	IQualifiedNameProvider qnp;

	@Override
	protected String getHoverInfoAsHtml(EObject o) {
		if (o instanceof CNodeDefinition)
			return this.getInfoCNodeDefinition((CNodeDefinition) o);
		return super.getHoverInfoAsHtml(o);
	}
	
	protected String getHeader(EObject o) {
		QualifiedName qn = qnp.getFullyQualifiedName(o);
		return o.eClass().getName() + ((qn.getSegmentCount() > 0) ? " <b>"+qn.toString()+"</b>" : "");
	}
	
	protected String getInfoCNodeDefinition(CNodeDefinition n) {
		
		StringBuffer buffer = new StringBuffer();
		buffer.append(this.getHeader(n));
		
		String description = n.getDefinition().getDescription().getValue();
		if (description != null && description.length() > 0) {
			buffer.append("<p>");
			buffer.append(description);
			buffer.append("</p>");
		}
		List<CNodeProvider> providers = n.getDefinition().getProviders();
		if (providers.size() > 0) {
			buffer.append("<p>");
			buffer.append("The available providers are the following:");
			providers.forEach((p) -> {
				buffer.append("<li>");
				buffer.append(p.getName() + " : " + p.getProvider().getName());
				buffer.append("</li>");
			});
			buffer.append("</p>");
		}
		return buffer.toString();
	}
	
}
