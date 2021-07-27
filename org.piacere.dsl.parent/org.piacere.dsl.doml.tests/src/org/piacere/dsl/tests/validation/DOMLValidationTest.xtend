package org.piacere.dsl.tests.validation

import org.eclipse.xpect.runner.XpectRunner
import org.eclipse.xpect.runner.XpectTestFiles
import org.junit.runner.RunWith

@RunWith(typeof(XpectRunner))
@XpectTestFiles(fileExtensions = "xt")
class DOMLValidationTest extends RMDFValidationTest {
	
}