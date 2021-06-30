/*
 * generated by Xtext 2.25.0
 */
package org.piacere.dsl.scoping;

import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;
import java.util.stream.StreamSupport;

import org.eclipse.emf.ecore.EObject;
import org.eclipse.emf.ecore.EReference;
import org.eclipse.xtext.EcoreUtil2;
import org.eclipse.xtext.naming.QualifiedName;
import org.eclipse.xtext.resource.IEObjectDescription;
import org.eclipse.xtext.resource.IResourceDescription;
import org.eclipse.xtext.resource.IResourceDescriptions;
import org.eclipse.xtext.scoping.IScope;
import org.eclipse.xtext.scoping.Scopes;
import org.eclipse.xtext.scoping.impl.FilteringScope;
import org.piacere.dsl.rMDF.CImport;
import org.piacere.dsl.rMDF.CNodeCrossRefGetValue;
import org.piacere.dsl.rMDF.CNodeType;
import org.piacere.dsl.rMDF.CProperty;
import org.piacere.dsl.rMDF.RMDFPackage;
import org.piacere.dsl.utils.Helper;

import com.google.inject.Inject;

/**
 * This class contains custom scoping description.
 * 
 * See https://www.eclipse.org/Xtext/documentation/303_runtime_concepts.html#scoping
 * on how and when to use it.
 */
public class RMDFScopeProvider extends AbstractRMDFScopeProvider {	

	@Inject
	private IResourceDescriptions descriptions;

	@Inject
	IResourceDescription.Manager mgr;

	@Override
	public IScope getScope(EObject context, EReference reference) {
		
		if (reference == RMDFPackage.Literals.CMETADATA__PROVIDER) {
			return super.getScope(context, reference);
		}

		if (reference == RMDFPackage.Literals.CNODE_PROPERTY__NAME) {
			Map<CProperty, QualifiedName> props = Helper.getAllCProperty(context, true);
			Map<CProperty, QualifiedName> properties = new HashMap<CProperty, QualifiedName>(props);
			
			EObject container = Helper.getContainer(context);
			Iterable<IEObjectDescription> elements = descriptions.getExportedObjectsByType(RMDFPackage.Literals.CNODE_TYPE);

			// This block adds to the Scope the properties of the resources that 
			// extends the given one, so properties can be overwritten.
			List<CNodeType> extendables = StreamSupport.stream(elements.spliterator(), false)
					.map((node) -> (CNodeType) EcoreUtil2.resolve(node.getEObjectOrProxy(), context))
					.filter((node) -> {
						if (container instanceof CNodeType &&
								!node.eIsProxy() &&
								node.getData() != null &&
								node.getData().getSuperType() != null) {
							return node.getData().getSuperType().getName() == ((CNodeType) container).getName();
						} 
						return false;
					})
					.collect(Collectors.toList());
			extendables.forEach((node) -> {
				properties.putAll(Helper.getCPropertyFromNodeType(node, null));
				properties.putAll(Helper.getCPropertyFromNodeTypeNodeTemplates(node, null));
			});

			return Scopes.scopeFor(properties.keySet(), (s) -> {
				return properties.get(s);
			}, IScope.NULLSCOPE);
		}

		if (reference == RMDFPackage.Literals.CNODE__TYPE ||
				reference == RMDFPackage.Literals.CNODE_TYPE_DATA__SUPER_TYPE) {
			return new FilteringScope(this.getImportedScope(context, reference), (s) -> {
				EObject obj = s.getEObjectOrProxy();
				return (obj instanceof CNodeType);
			});
		}

		if (reference == RMDFPackage.Literals.CNODE_CROSS_REF_GET_VALUE__CROSSVALUE) {
			if (((CNodeCrossRefGetValue) context).isSuper()) {
				CNodeType container = EcoreUtil2.getContainerOfType(context, CNodeType.class);
				Map<CProperty, QualifiedName> properties = Helper.getCPropertyFromNodeType(container.getData().getSuperType(), null);
				return Scopes.scopeFor(properties.keySet(), (s) -> {
					return properties.get(s);
				}, IScope.NULLSCOPE);
			}
		}

		EObject root = EcoreUtil2.getRootContainer(context);
		return new FilteringScope(super.getScope(context, reference), (s) -> {
			EObject inneroot = EcoreUtil2.getRootContainer(s.getEObjectOrProxy());
			return root.equals(inneroot);
		});
	}

	/**
	 * Returns a scope of the given context only for imported namespace
	 * 
	 * @param context the element from which an element shall be referenced
	 * @param reference the reference for which to get the scope
	 * @return
	 */
	protected IScope getImportedScope(EObject context, EReference reference) {
		EObject root = EcoreUtil2.getRootContainer(context);
		List<CImport> imports = EcoreUtil2.getAllContentsOfType(root, CImport.class);
		return new FilteringScope(super.getScope(context, reference), (s) -> {
			// If it is on the same file, we do not need an import
			EObject inneroot = EcoreUtil2.getRootContainer(s.getEObjectOrProxy());
			if (root.equals(inneroot))
				return true;

			return imports.stream().anyMatch((i) -> {		
				if (i.getImportedName() == null)
					return false;
				QualifiedName importedName = QualifiedName.create(i.getImportedName().split("\\."));
				if (importedName.getLastSegment().equalsIgnoreCase("*")) {
					importedName = importedName.skipLast(1);
					return s.getQualifiedName().startsWithIgnoreCase(importedName);
				} else {
					return s.getQualifiedName().equals(importedName);
				}
			});
		});
	}

}
