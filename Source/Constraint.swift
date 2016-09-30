//
//  SnapKit
//
//  Copyright (c) 2011-Present SnapKit Team - https://github.com/SnapKit
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.

#if os(iOS) || os(tvOS)
    import UIKit
#else
    import AppKit
#endif

public class Constraint {
    
    internal let sourceLocation: (String, UInt)
    internal let label: String?
    
    private let from: ConstraintItem
    private let to: ConstraintItem
    private let relation: ConstraintRelation
    private let multiplier: ConstraintMultiplierTarget
    private var constant: ConstraintConstantTarget {
        didSet {
            self.updateConstantAndPriorityIfNeeded()
        }
    }
    private var priority: ConstraintPriorityTarget {
        didSet {
          self.updateConstantAndPriorityIfNeeded()
        }
    }
    private var layoutConstraints: [LayoutConstraint]
    
    // MARK: Initialization
    
    internal init(from: ConstraintItem,
                  to: ConstraintItem,
                  relation: ConstraintRelation,
                  sourceLocation: (String, UInt),
                  label: String?,
                  multiplier: ConstraintMultiplierTarget,
                  constant: ConstraintConstantTarget,
                  priority: ConstraintPriorityTarget) {
        self.from = from
        self.to = to
        self.relation = relation
        self.sourceLocation = sourceLocation
        self.label = label
        self.multiplier = multiplier
        self.constant = constant
        self.priority = priority
        self.layoutConstraints = []
        
        // get attributes
        let layoutFromAttributes = self.from.attributes.layoutAttributes
        let layoutToAttributes = self.to.attributes.layoutAttributes
        
        // get layout from
        let layoutFrom: ConstraintView = self.from.view!
        
        // get relation
        let layoutRelation = self.relation.layoutRelation
        
        for layoutFromAttribute in layoutFromAttributes {
            // get layout to attribute
            let layoutToAttribute: NSLayoutAttribute
            if #available(iOSApplicationExtension 8.0, *) {//pzz.zzp
                #if os(iOS) || os(tvOS)
                    if layoutToAttributes.count > 0 {
                        if self.from.attributes == .edges && self.to.attributes == .margins {
                            switch layoutFromAttribute {
                            case .left:
                                layoutToAttribute = .leftMargin
                            case .right:
                                layoutToAttribute = .rightMargin
                            case .top:
                                layoutToAttribute = .topMargin
                            case .bottom:
                                layoutToAttribute = .bottomMargin
                            default:
                                fatalError()
                            }
                        } else if self.from.attributes == .margins && self.to.attributes == .edges {
                            switch layoutFromAttribute {
                            case .leftMargin:
                                layoutToAttribute = .left
                            case .rightMargin:
                                layoutToAttribute = .right
                            case .topMargin:
                                layoutToAttribute = .top
                            case .bottomMargin:
                                layoutToAttribute = .bottom
                            default:
                                fatalError()
                            }
                        } else if self.from.attributes == self.to.attributes {
                            layoutToAttribute = layoutFromAttribute
                        } else {
                            layoutToAttribute = layoutToAttributes[0]
                        }
                    } else {
                        layoutToAttribute = layoutFromAttribute
                    }
                #else
                    if layoutToAttributes.count > 0 {
                        layoutToAttribute = layoutToAttributes[0]
                    } else {
                        layoutToAttribute = layoutFromAttribute
                    }
                #endif
            } else {//pzz.zzp
                // Fallback on earlier versions
                #if os(iOS) || os(tvOS)
                    if layoutToAttributes.count > 0 {
//                        if self.from.attributes == .edges && self.to.attributes == .margins {
//                            switch layoutFromAttribute {
//                            case .left:
//                                layoutToAttribute = .leftMargin
//                            case .right:
//                                layoutToAttribute = .rightMargin
//                            case .top:
//                                layoutToAttribute = .topMargin
//                            case .bottom:
//                                layoutToAttribute = .bottomMargin
//                            default:
//                                fatalError()
//                            }
//                        } else if self.from.attributes == .margins && self.to.attributes == .edges {
//                            switch layoutFromAttribute {
//                            case .leftMargin:
//                                layoutToAttribute = .left
//                            case .rightMargin:
//                                layoutToAttribute = .right
//                            case .topMargin:
//                                layoutToAttribute = .top
//                            case .bottomMargin:
//                                layoutToAttribute = .bottom
//                            default:
//                                fatalError()
//                            }
//                        } else
                            if self.from.attributes == self.to.attributes {
                            layoutToAttribute = layoutFromAttribute
                        } else {
                            layoutToAttribute = layoutToAttributes[0]
                        }
                    } else {
                        layoutToAttribute = layoutFromAttribute
                    }
                #else
                    if layoutToAttributes.count > 0 {
                        layoutToAttribute = layoutToAttributes[0]
                    } else {
                        layoutToAttribute = layoutFromAttribute
                    }
                #endif
            }
            
            // get layout constant
            let layoutConstant: CGFloat = self.constant.constraintConstantTargetValueFor(layoutAttribute: layoutToAttribute)
            
            // get layout to
            var layoutTo: AnyObject? = self.to.target
            
            // use superview if possible
            if layoutTo == nil && layoutToAttribute != .width && layoutToAttribute != .height {
                layoutTo = layoutFrom.superview
            }
            
            // create layout constraint
            let layoutConstraint = LayoutConstraint(
                item: layoutFrom,
                attribute: layoutFromAttribute,
                relatedBy: layoutRelation,
                toItem: layoutTo,
                attribute: layoutToAttribute,
                multiplier: self.multiplier.constraintMultiplierTargetValue,
                constant: layoutConstant
            )
            
            // set label
            layoutConstraint.label = self.label
            
            // set priority
            layoutConstraint.priority = self.priority.constraintPriorityTargetValue
            
            // set constraint
            layoutConstraint.constraint = self
            
            // append
            self.layoutConstraints.append(layoutConstraint)
        }
    }
    
    // MARK: Public
    
    @available(*, deprecated:3.0, message:"Use activate().")
    public func install() {
        self.activate()
    }
    
    @available(*, deprecated:3.0, message:"Use deactivate().")
    public func uninstall() {
        self.deactivate()
    }
    
    public func activate() {
        self.activateIfNeeded()
    }
    
    public func deactivate() {
        self.deactivateIfNeeded()
    }
    
    @discardableResult
    public func update(offset: ConstraintOffsetTarget) -> Constraint {
        self.constant = offset.constraintOffsetTargetValue
        return self
    }
    
    @discardableResult
    public func update(inset: ConstraintInsetTarget) -> Constraint {
        self.constant = inset.constraintInsetTargetValue
        return self
    }
    
    @discardableResult
    public func update(priority: ConstraintPriorityTarget) -> Constraint {
        self.priority = priority.constraintPriorityTargetValue
        return self
    }
    
    @available(*, deprecated:3.0, message:"Use update(offset: ConstraintOffsetTarget) instead.")
    public func updateOffset(amount: ConstraintOffsetTarget) -> Void { self.update(offset: amount) }
    
    @available(*, deprecated:3.0, message:"Use update(inset: ConstraintInsetTarget) instead.")
    public func updateInsets(amount: ConstraintInsetTarget) -> Void { self.update(inset: amount) }
    
    @available(*, deprecated:3.0, message:"Use update(priority: ConstraintPriorityTarget) instead.")
    public func updatePriority(amount: ConstraintPriorityTarget) -> Void { self.update(priority: amount) }
    
    @available(*, obsoleted:3.0, message:"Use update(priority: ConstraintPriorityTarget) instead.")
    public func updatePriorityRequired() -> Void {}
    
    @available(*, obsoleted:3.0, message:"Use update(priority: ConstraintPriorityTarget) instead.")
    public func updatePriorityHigh() -> Void { fatalError("Must be implemented by Concrete subclass.") }
    
    @available(*, obsoleted:3.0, message:"Use update(priority: ConstraintPriorityTarget) instead.")
    public func updatePriorityMedium() -> Void { fatalError("Must be implemented by Concrete subclass.") }
    
    @available(*, obsoleted:3.0, message:"Use update(priority: ConstraintPriorityTarget) instead.")
    public func updatePriorityLow() -> Void { fatalError("Must be implemented by Concrete subclass.") }
    
    // MARK: Internal
    
    internal func updateConstantAndPriorityIfNeeded() {
        for layoutConstraint in self.layoutConstraints {
            let attribute = (layoutConstraint.secondAttribute == .notAnAttribute) ? layoutConstraint.firstAttribute : layoutConstraint.secondAttribute
            layoutConstraint.constant = self.constant.constraintConstantTargetValueFor(layoutAttribute: attribute)
            layoutConstraint.priority = self.priority.constraintPriorityTargetValue
        }
    }
    
    internal func activateIfNeeded(updatingExisting: Bool = false) {
        let view = self.from.view!
        let layoutConstraints = self.layoutConstraints
        let existingLayoutConstraints = view.snp.layoutConstraints
        
        if updatingExisting {
            for layoutConstraint in layoutConstraints {
                let existingLayoutConstraint = existingLayoutConstraints.first { $0 == layoutConstraint }
                guard let updateLayoutConstraint = existingLayoutConstraint else {
                    fatalError("Updated constraint could not find existing matching constraint to update: \(layoutConstraint)")
                }
                
                let updateLayoutAttribute = (updateLayoutConstraint.secondAttribute == .notAnAttribute) ? updateLayoutConstraint.firstAttribute : updateLayoutConstraint.secondAttribute
                updateLayoutConstraint.constant = self.constant.constraintConstantTargetValueFor(layoutAttribute: updateLayoutAttribute)
            }
        } else {
            if #available(iOSApplicationExtension 8.0, *) {//pzz.zzp
                NSLayoutConstraint.activate(layoutConstraints)
            } else {
                // Fallback on earlier versions
                do {//iOS7:pzz.zzp
                    var installOnView: UIView? = nil
                    installOnView = pzz_toget_installOnView()
                    installOnView?.addConstraints(layoutConstraints)
                }
            }
            view.snp.add(layoutConstraints: layoutConstraints)
        }
    }
    
    internal func deactivateIfNeeded() {
        let view = self.from.view!
        let layoutConstraints = self.layoutConstraints
        if #available(iOSApplicationExtension 8.0, *) {//pzz.zzp
            NSLayoutConstraint.deactivate(layoutConstraints)
        } else {
            // Fallback on earlier versions
            do {//iOS7:pzz.zzp
                var installOnView: UIView? = nil
                installOnView = pzz_toget_installOnView()
                installOnView?.removeConstraints(layoutConstraints)
            }
        }
        view.snp.remove(layoutConstraints: layoutConstraints)
    }
    
    
    //iOS7:pzz.zzp(这个是直接从0.22.0中拿过来的)
    private func closestCommonSuperviewFromView(fromView: UIView?, toView: UIView?) -> UIView? {
        var views = Set<UIView>()
        var fromView = fromView
        var toView = toView
        repeat {
            if let view = toView {
                if views.contains(view) {
                    return view
                }
                views.insert(view)
                toView = view.superview
            }
            if let view = fromView {
                if views.contains(view) {
                    return view
                }
                views.insert(view)
                fromView = view.superview
            }
        } while (fromView != nil || toView != nil)
        
        return nil
    }
    //iOS7:pzz.zzp(这个是从我写的)
    private func pzz_toget_installOnView() -> UIView? {
        var installOnView: UIView? = nil
        if self.to.view != nil {
            installOnView = closestCommonSuperviewFromView(fromView: self.from.view, toView: self.to.view)
            if installOnView == nil {
                NSException(name: NSExceptionName(rawValue: "Cannot Install Constraint"), reason: "No common superview between views (@\(self.sourceLocation.0)#\(self.sourceLocation.1))", userInfo: nil).raise()//self.makerFile#\self.makerLine
                //return []
            }
        } else {
            if self.from.attributes.isSubset(of: ConstraintAttributes.width.union(.height)) {//宽高时
                installOnView = self.from.view
            } else {
                installOnView = self.from.view?.superview
                if installOnView == nil {
                    NSException(name: NSExceptionName(rawValue: "Cannot Install Constraint"), reason: "Missing superview (@\(self.sourceLocation.0)#\(self.sourceLocation.1))", userInfo: nil).raise()
                    //return []
                }
            }
        }
        return installOnView
    }
    
}
