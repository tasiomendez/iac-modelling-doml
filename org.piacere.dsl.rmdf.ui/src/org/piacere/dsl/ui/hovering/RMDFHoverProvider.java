package org.piacere.dsl.ui.hovering;

import org.eclipse.emf.ecore.EObject;
import org.eclipse.xtext.naming.IQualifiedNameProvider;
import org.eclipse.xtext.naming.QualifiedName;
import org.eclipse.xtext.ui.editor.hover.html.DefaultEObjectHoverProvider;
import org.piacere.dsl.rMDF.CBOOLEAN;
import org.piacere.dsl.rMDF.CFLOAT;
import org.piacere.dsl.rMDF.CProperty;
import org.piacere.dsl.rMDF.CPropertyBody;
import org.piacere.dsl.rMDF.CSIGNEDINT;
import org.piacere.dsl.rMDF.CSTRING;
import org.piacere.dsl.rMDF.CValueData;
import org.piacere.dsl.rMDF.CValueExpression;

import com.google.inject.Inject;

public class RMDFHoverProvider extends DefaultEObjectHoverProvider {

	@Inject
	IQualifiedNameProvider qnp;
		
	@Override
	protected String getHoverInfoAsHtml(EObject o) {
		if (o instanceof CProperty)
			return this.getInfoCProperty((CProperty) o);
		return super.getHoverInfoAsHtml(o);
	}
	
	protected String getInfoCProperty(CProperty p) {
		// https://stackoverflow.com/questions/57206109/allow-multiline-string-in-xtext-grammar-to-embed-javascript-code
		
		// https://zarnekow.blogspot.com/2011/06/customizing-content-assist-with-xtext.html
		
		StringBuffer buffer = new StringBuffer();
		buffer.append(this.getHeader(p));
		
		CPropertyBody body = p.getProperty();
		
		String description = body.getDescription().getValue();
		if (description != null && description.length() > 0) {
			buffer.append("<p>");
			buffer.append(description);
			buffer.append("</p>");
		}
		buffer.append("<p>");
		CValueData valueData = body.getType();
		String type = (valueData.getPredefined() != null) ? 
				valueData.getPredefined() : valueData.getDatatype().getName();
		buffer.append("<b>type: </b>" + type);
		buffer.append("<br>");
		
		if (body.getDefault() != null) {
			CValueExpression defaultValue = body.getDefault();
			String dv = defaultValue.toString();
			if (defaultValue instanceof CSTRING)
				dv = ((CSTRING) defaultValue).getValue();
			else if (defaultValue instanceof CFLOAT)
				dv = Float.toString(((CFLOAT) defaultValue).getValue());
			else if (defaultValue instanceof CSIGNEDINT)
				dv = Integer.toString(((CSIGNEDINT) defaultValue).getValue());
			else if (defaultValue instanceof CBOOLEAN)
				dv = Boolean.toString(((CBOOLEAN) defaultValue).isValue());
			
			if (dv.isEmpty())
				dv = "<i> &#60;empty&#62; </i>";
			
			buffer.append("<b>default: </b>" + dv);
			buffer.append("<br>");
		}
		
		if (body.getRequired() != null && body.getRequired().isValue())
			buffer.append("<b>required: </b>" + body.getRequired().isValue());
		else buffer.append("<b>required: </b> false");
		buffer.append("<br>");
		
		if (body.getMultiple() != null && body.getMultiple().isValue())
			buffer.append("<b>multiple: </b>" + body.getMultiple().isValue());
		else buffer.append("<b>multiple: </b> false");
		buffer.append("<br>");
		
		buffer.append("</p>");
		return buffer.toString();
	}
	
	protected String getHeader(EObject o) {
		QualifiedName qn = qnp.getFullyQualifiedName(o);
		return o.eClass().getName() + ((qn.getSegmentCount() > 0) ? " <b>"+qn.toString()+"</b>" : "");
	}
	
}
