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
import org.piacere.dsl.rMDF.RMDFModel
import org.piacere.dsl.tests.linking.RMDFLinkingTest
import org.piacere.dsl.tests.parser.RMDFParserTest
import org.piacere.dsl.tests.scoping.RMDFScopeTest
import org.piacere.dsl.tests.validation.RMDFValidationTest

@ExtendWith(typeof(InjectionExtension))
@InjectWith(typeof(RMDFInjectorProvider))
@SuiteClasses(#[
	typeof(RMDFLinkingTest),
	typeof(RMDFParserTest),
	typeof(RMDFScopeTest),
	typeof(RMDFValidationTest)
]) 
@RunWith(typeof(Suite)) 
@XpectTestFiles(fileExtensions = "xt")
class RMDFXpectTests {
	 
	@Inject 
	extension ParseHelper<RMDFModel> parseHelper

	@Test 
	def void fileExtension() {
		Assertions.assertEquals("rmdf", parseHelper.fileExtension)
	}
}
