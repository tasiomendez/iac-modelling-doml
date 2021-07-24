package org.piacere.dsl.validation

import org.eclipse.emf.ecore.EObject
import org.eclipse.emf.ecore.EStructuralFeature
import org.piacere.dsl.rMDF.CBOOLEAN
import org.piacere.dsl.rMDF.CFLOAT
import org.piacere.dsl.rMDF.CMultipleValueExpression
import org.piacere.dsl.rMDF.CNodeCrossRefGetValue
import org.piacere.dsl.rMDF.CNodeNestedProperty
import org.piacere.dsl.rMDF.CProperty
import org.piacere.dsl.rMDF.CSIGNEDINT
import org.piacere.dsl.rMDF.CSTRING
import org.piacere.dsl.rMDF.CValueData

/** 
 * Handler implementation with general getType method
 */
class RMDFHandler {
	
	protected EStructuralFeature feature
	protected Validator function

	new (Validator function, EStructuralFeature feature) {
		this.function = function
		this.feature = feature
	}
	
	def void handle(EObject property, CProperty definition) {
		switch (property) {
			CSTRING: this.handle(property, definition)
			CFLOAT: this.handle(property, definition)
			CSIGNEDINT: this.handle(property, definition)
			CBOOLEAN: this.handle(property, definition)
			CNodeCrossRefGetValue: this.handle(property, definition)
			CMultipleValueExpression: this.handle(property, definition)
			CNodeNestedProperty: this.handle(property, definition)
		}
	}

	def protected String getType(CValueData type) {
		return if(type.getPredefined() === null) type.getDatatype().getName() else type.getPredefined()
	}

	def private void handle(CSTRING property, CProperty definition) {
		var String type = this.getType(definition.getProperty().getType())
		if(!type.equals("String")) 
			this.function.print('''«definition.getName()» should be a «type»''', this.feature)
	}

	def private void handle(CFLOAT property, CProperty definition) {
		var String type = this.getType(definition.getProperty().getType())
		if(!type.equals("Integer")) 
			this.function.print('''«definition.getName()» should be a «type»''', this.feature)
	}

	def private void handle(CSIGNEDINT property, CProperty definition) {
		var String type = this.getType(definition.getProperty().getType())
		if(!type.equals("Integer")) 
			this.function.print('''«definition.getName()» should be a «type»''', this.feature)
	}

	def private void handle(CBOOLEAN property, CProperty definition) {
		var String type = this.getType(definition.getProperty().getType())
		if(!type.equals("Boolean")) 
			this.function.print('''«definition.getName()» should be a «type»''', this.feature)
	}

	def private void handle(CNodeCrossRefGetValue property, CProperty definition) {
		var String type = this.getType(definition.getProperty().getType())
		var CProperty prop = ((property as CNodeCrossRefGetValue)).getCrossvalue()
		if(!type.equals(prop.getProperty().getType().getPredefined())) 
			this.function.print('''«definition.getName()» should be a «type». Try changing input variable «prop.getName()»''',
				this.feature)
	}

	def private void handle(CMultipleValueExpression property, CProperty definition) {
		if(definition.getProperty().getMultiple() === null || !definition.getProperty().getMultiple().isValue()) 
			this.function.print('''«definition.getName()» does not support multiple values''', this.feature)
	}

	def private void handle(CNodeNestedProperty property, CProperty definition) {
		if(definition.getProperty().getType().getDatatype() === null) 
			this.function.print('''«definition.getName()» should be a «this.getType(definition.getProperty().getType())»''',
				this.feature)
	}

	@FunctionalInterface 
	protected interface Validator {
		def void print(String string, EStructuralFeature feature)
	}
}
