package org.piacere.dsl.tests.parser

import org.eclipse.xpect.runner.XpectRunner
import org.eclipse.xpect.runner.XpectTestFiles
import org.junit.runner.RunWith

@RunWith(typeof(XpectRunner))
@XpectTestFiles(fileExtensions = "xt")
class DOMLParserTest extends RMDFParserTest {
	
}