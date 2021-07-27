package org.piacere.dsl.tests.scoping

import org.eclipse.xpect.runner.XpectRunner
import org.eclipse.xpect.runner.XpectTestFiles
import org.eclipse.xpect.xtext.lib.tests.ScopingTest
import org.junit.runner.RunWith

@RunWith(typeof(XpectRunner))
@XpectTestFiles(fileExtensions = "xt")
class RMDFScopeTest extends ScopingTest {
	
}
