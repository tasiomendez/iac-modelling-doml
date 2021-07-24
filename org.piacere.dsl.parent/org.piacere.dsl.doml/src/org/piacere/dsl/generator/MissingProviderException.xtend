package org.piacere.dsl.generator

import org.eclipse.emf.ecore.EObject
import org.eclipse.xtext.EcoreUtil2
import org.piacere.dsl.dOML.DOMLModel
import org.piacere.dsl.rMDF.CProvider
import org.piacere.dsl.rMDF.RMDFModel
import org.piacere.dsl.utils.TreeNodeTemplate

class MissingProviderException extends Exception {
	
	val TreeNodeTemplate tree
	val Iterable<CProvider> availability

	new(TreeNodeTemplate tree, Iterable<CProvider> availability) {
		super()
		this.tree = tree
		this.availability = availability
	}

	def getProvider() {
		return this.tree.root.provider
	}

	def getAvailability() {
		return this.availability
	}
	
	def getName() {
		return this.tree.name
	}

	def private getProvider(EObject obj) {
		val root = EcoreUtil2.getRootContainer(obj)
		return switch root {
			RMDFModel: root.metadata.provider
			DOMLModel: root.metadata.provider
		}
	}
}
