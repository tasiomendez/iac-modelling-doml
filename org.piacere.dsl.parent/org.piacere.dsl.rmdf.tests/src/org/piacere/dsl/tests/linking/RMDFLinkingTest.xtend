package org.piacere.dsl.tests.linking

import org.eclipse.xpect.runner.XpectRunner
import org.eclipse.xpect.runner.XpectTestFiles
import org.eclipse.xpect.xtext.lib.tests.LinkingTest
import org.junit.runner.RunWith

@RunWith(typeof(XpectRunner))
@XpectTestFiles(fileExtensions = "xt")
class RMDFLinkingTest extends LinkingTest {
	
}