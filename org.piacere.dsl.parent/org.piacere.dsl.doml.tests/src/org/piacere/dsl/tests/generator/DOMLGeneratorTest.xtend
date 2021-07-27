package org.piacere.dsl.tests.generator

import org.eclipse.xpect.runner.XpectRunner
import org.eclipse.xpect.runner.XpectTestFiles
import org.eclipse.xpect.xtext.lib.tests.GeneratorTest
import org.junit.runner.RunWith

@RunWith(typeof(XpectRunner))
@XpectTestFiles(fileExtensions = "xt")
class DOMLGeneratorTest extends GeneratorTest {
	
}