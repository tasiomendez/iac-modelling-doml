/*
 * generated by Xtext 2.25.0
 */
package org.piacere.dsl.formatting2

import com.google.inject.Inject
import org.eclipse.xtext.formatting2.AbstractFormatter2
import org.eclipse.xtext.formatting2.IFormattableDocument
import org.piacere.dsl.rMDF.CMetadata
import org.piacere.dsl.rMDF.RMDFModel
import org.piacere.dsl.services.RMDFGrammarAccess

class RMDFFormatter extends AbstractFormatter2 {
	
	@Inject extension RMDFGrammarAccess

	def dispatch void format(RMDFModel rMDFModel, extension IFormattableDocument document) {
		// TODO: format HiddenRegions around keywords, attributes, cross references, etc. 
		rMDFModel.metadata.format
		rMDFModel.imports.format
		rMDFModel.datatypes.format
		rMDFModel.nodetypes.format
	}

	def dispatch void format(CMetadata cMetadata, extension IFormattableDocument document) {
		// TODO: format HiddenRegions around keywords, attributes, cross references, etc. 
		cMetadata.version.format
		cMetadata.description.format
	}
	
	// TODO: implement for CImports, CDataTypes, CDataType, CDataTypeData, CNodeTypes, CNodeType, CNodeTypeData, CProperty, CPropertyBody, CNodeTemplates, CNodeTemplate, CNode, CNodeProperty, CNodeNestedProperty, CMultipleValueExpression, CMultipleNestedProperty, CConcatValues, CNodeRelationships
}