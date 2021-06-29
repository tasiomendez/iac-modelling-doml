package org.piacere.dsl.generator

import org.eclipse.emf.common.util.URI
import org.eclipse.emf.ecore.resource.Resource
import org.eclipse.xtext.generator.IFileSystemAccess2
import org.eclipse.xtext.generator.IGeneratorContext
import org.piacere.dsl.dOML.CInputVariable
import org.piacere.dsl.dOML.CNodeCrossRefGetInput
import org.piacere.dsl.dOML.COutputVariable
import org.piacere.dsl.rMDF.CConcatValues
import org.piacere.dsl.rMDF.CIntrinsicFunctions
import org.piacere.dsl.rMDF.CNodeCrossRefGetAttribute
import org.piacere.dsl.rMDF.CNodeCrossRefGetValue
import org.piacere.dsl.rMDF.CNodePropertyValueInlineSingle
import org.piacere.dsl.rMDF.CValueExpression

class TerraformGenerator extends DOMLGenerator {
	
	override void doGenerate(Resource resource, IFileSystemAccess2 fsa, IGeneratorContext context) {
		val filename = this.getFilename(resource.URI)
		fsa.generateFile(filename, resource.compile)
	}
	
	override getFilename(URI uri) {
		super.getFilename(uri) + '.tf'
	}
	
	override compile(Resource resource) '''
		«resource.header»
		
		««« inputs:
		«FOR i : resource.allContents.toIterable.filter(CInputVariable) BEFORE this.title("Input Variables")»
			«i.compile»
		«ENDFOR»
		
		««« outputs:
		«FOR i : resource.allContents.toIterable.filter(COutputVariable) BEFORE this.title("Output Variables")»
			«i.compile»
		«ENDFOR»
		
	'''
	
	override compile(CInputVariable variable) '''
		variable "«variable.name»" {
			«IF variable.data.type !== null»
				type        = «this.trim(variable.data.type?.predefined.toLowerCase)»
			«ENDIF»
			«IF variable.data.description !== null»
				description = "«this.trim(variable.data.description?.value)»"
			«ENDIF»
			«IF variable.data.^default !== null»
				default     = «this.getValueExpr(variable.data.^default, true)»
			«ENDIF»
		}
		
	'''
	
	override compile(COutputVariable variable) '''
		output "«variable.name»" {
			«IF variable.value !== null»
				value = "«this.getValueExprInline(variable.value as CNodePropertyValueInlineSingle)»"
			«ENDIF»
		}
		
	'''

	override getValueExprInline(CNodePropertyValueInlineSingle expr) {
		switch expr {
			CValueExpression: this.getValueExpr(expr, false)
			CIntrinsicFunctions: this.getIntrinsicFunction(expr)
			default: ''
		}
	}

	override compile(CConcatValues expr) '''
		«this.getValueExprInline(expr.first)»«FOR i : expr.list»«this.getValueExprInline(i as CNodePropertyValueInlineSingle)»«ENDFOR»'''

	override compile(CNodeCrossRefGetInput expr) '''
		${var.«expr.input.name»}'''

	override compile(CNodeCrossRefGetAttribute expr) '''
		${«this.transformName(expr.node.template.type.name)».«expr.node.name».«expr.attr»}'''

	override compile(CNodeCrossRefGetValue expr) '''
		"PENDING TO IMPLEMENT"'''
	
	def transformName(String name) {
		name.replace(".", "_")
	}
	
	def title(String title)'''
		#####################
		# «title» 
		#####################
		
	'''
	
}