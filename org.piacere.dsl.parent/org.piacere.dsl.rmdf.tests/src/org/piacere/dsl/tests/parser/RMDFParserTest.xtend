package org.piacere.dsl.tests.parser

import org.eclipse.emf.ecore.EObject
import org.eclipse.xpect.XpectImport
import org.eclipse.xpect.expectation.IStringExpectation
import org.eclipse.xpect.expectation.StringExpectation
import org.eclipse.xpect.runner.Xpect
import org.eclipse.xpect.runner.XpectRunner
import org.eclipse.xpect.runner.XpectTestFiles
import org.eclipse.xpect.xtext.lib.setup.ThisModel
import org.eclipse.xpect.xtext.lib.setup.XtextStandaloneSetup
import org.eclipse.xpect.xtext.lib.setup.XtextWorkspaceSetup
import org.eclipse.xpect.xtext.lib.util.EObjectFormatter
import org.junit.runner.RunWith

@XpectImport(#[
	typeof(XtextStandaloneSetup), 
	typeof(XtextWorkspaceSetup)
])
@RunWith(typeof(XpectRunner))
@XpectTestFiles(fileExtensions = "xt")
class RMDFParserTest {
	
	@Xpect
	def void parse(@StringExpectation IStringExpectation expectation, @ThisModel EObject model) {
		val actual = new EObjectFormatter().resolveCrossReferences().format(model);
		expectation.assertEquals(actual);
	}
	
}