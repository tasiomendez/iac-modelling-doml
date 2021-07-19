/*
 * generated by Xtext 2.25.0
 */
package org.piacere.dsl.generator

import com.google.inject.Inject
import org.eclipse.emf.ecore.resource.Resource
import org.eclipse.xtext.generator.AbstractGenerator
import org.eclipse.xtext.generator.IFileSystemAccess2
import org.eclipse.xtext.generator.IGeneratorContext
import org.eclipse.xtext.resource.IResourceDescriptions

/**
 * Generates code from your model files on save.
 * 
 * See https://www.eclipse.org/Xtext/documentation/303_runtime_concepts.html#code-generation
 */
class DOMLGenerator extends AbstractGenerator {

	@Inject
	IResourceDescriptions descriptions

	val toscaGenerator = new TOSCAGenerator
	val terraformGenerator = new TerraformGenerator

	override void doGenerate(Resource resource, IFileSystemAccess2 fsa, IGeneratorContext context) {
		this.toscaGenerator.doGenerate(resource, fsa, context, this.descriptions)
		this.terraformGenerator.doGenerate(resource, fsa, context, this.descriptions)
	}
}
