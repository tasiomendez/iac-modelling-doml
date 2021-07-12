package org.piacere.dsl.validation

import org.eclipse.emf.ecore.EObject
import org.eclipse.emf.ecore.EStructuralFeature
import org.piacere.dsl.dOML.CInputVariable
import org.piacere.dsl.dOML.CNodeCrossRefGetInput
import org.piacere.dsl.rMDF.CProperty

class DOMLHandler extends RMDFHandler {
	
	new (Validator function, EStructuralFeature feature) {
		super(function, feature)
	}

	override void handle(EObject property, CProperty definition) {
		switch(property) {
			CNodeCrossRefGetInput: this.handle(property, definition)
			default: super.handle(property, definition)
		}
	}

	def protected void handle(CNodeCrossRefGetInput property, CProperty definition) {
		var String type = this.getType(definition.getProperty().getType())
		var CInputVariable input = ((property as CNodeCrossRefGetInput)).getInput()
		
		if(!type.equals(input.getData().getType().getPredefined())) 
			this.function.print('''«definition.getName()» should be a «type». Try changing input variable «input.getName()»''',
				this.feature)
	}
}
