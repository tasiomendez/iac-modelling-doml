package org.piacere.dsl.tests

import com.google.inject.Inject
import org.eclipse.xpect.runner.XpectTestFiles
import org.eclipse.xtext.testing.InjectWith
import org.eclipse.xtext.testing.extensions.InjectionExtension
import org.eclipse.xtext.testing.util.ParseHelper
import org.junit.jupiter.api.Assertions
import org.junit.jupiter.api.Test
import org.junit.jupiter.api.^extension.ExtendWith
import org.junit.runner.RunWith
import org.junit.runners.Suite
import org.junit.runners.Suite.SuiteClasses
import org.piacere.dsl.dOML.DOMLModel
import org.piacere.dsl.tests.linking.DOMLLinkingTest
import org.piacere.dsl.tests.parser.DOMLParserTest
import org.piacere.dsl.tests.validation.DOMLValidationTest

@ExtendWith(typeof(InjectionExtension))
@InjectWith(typeof(DOMLInjectorProvider))
@SuiteClasses(#[
	typeof(DOMLLinkingTest),
	typeof(DOMLParserTest),
	typeof(DOMLValidationTest)
]) 
@RunWith(typeof(Suite)) 
@XpectTestFiles(fileExtensions = "xt")
class DOMLTests {
	
	@Inject 
	extension ParseHelper<DOMLModel> parseHelper

	@Test 
	def void fileExtension() {
		Assertions.assertEquals("doml", parseHelper.fileExtension)
	}
}
