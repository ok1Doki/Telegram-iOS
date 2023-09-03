import Foundation
import UIKit
import AsyncDisplayKit
import Display
import TelegramPresentationData
import SearchBarNode

public class ShowArchiveBarContentNode: NavigationBarContentNode {
    public var theme: PresentationTheme?
    private var state: State?

    private let inline: Bool
    public let strings: PresentationStrings
    private let titleNode: ImmediateTextNode

    private let backgroundNode = ASDisplayNode()
    private let backgroundLayer = CAGradientLayer()
    private let expandableBackgroundNode = ASDisplayNode()
    private let expandableBackgroundLayer = CAGradientLayer()

    public var expansionProgress: CGFloat = 1.0
    public var additionalHeight: CGFloat = 0.0

    private var validLayout: (CGSize, CGFloat, CGFloat)?

    public init(theme: PresentationTheme, strings: PresentationStrings, compactPlaceholder: String? = nil, inline: Bool = false) {
        self.theme = theme
        self.strings = strings
        self.inline = inline

        self.backgroundLayer.colors = [UIColor(rgb: 0x989ea5).cgColor, UIColor(rgb: 0xdadae0).cgColor]
        self.backgroundLayer.locations = [0, 1]
        self.backgroundLayer.startPoint = CGPoint(x: 0.0, y: 0.5)
        self.backgroundLayer.endPoint = CGPoint(x: 1.0, y: 0.5)
        self.backgroundNode.layer.addSublayer(self.backgroundLayer)

        self.expandableBackgroundLayer.colors = [UIColor(rgb: 0x173f70).cgColor, UIColor(rgb: 0x75c7fe).cgColor]
        self.expandableBackgroundLayer.locations = [0.0, 0.2, 0.8, 1.0]
        self.expandableBackgroundLayer.startPoint = CGPoint(x: 0.0, y: 0.5)
        self.expandableBackgroundLayer.endPoint = CGPoint(x: 1.0, y: 0.5)
        self.expandableBackgroundLayer.cornerRadius = 10
        self.expandableBackgroundNode.cornerRadius = 10
        self.expandableBackgroundNode.layer.addSublayer(self.expandableBackgroundLayer)

        self.titleNode = ImmediateTextNode()
        self.titleNode.maximumNumberOfLines = 1

        super.init()
        super.view.clipsToBounds = true

        self.addSubnode(self.backgroundNode)
        self.addSubnode(self.expandableBackgroundNode)
        self.addSubnode(self.titleNode)
    }

    override public func updateLayout(size: CGSize, leftInset: CGFloat, rightInset: CGFloat, transition: ContainedViewLayoutTransition) {
        self.validLayout = (size, leftInset, rightInset)
        let transition: ContainedViewLayoutTransition = .animated(duration: 0.6, curve: .spring)

        let textSize = self.titleNode.updateLayout(CGSize(width: size.width - 40.0, height: size.height))
        let textFrame = CGRect(origin: CGPoint(x: floor((size.width - textSize.width) / 2.0), y: size.height - 30.0), size: textSize)
        transition.updateFrame(node: self.titleNode, frame: textFrame)

        transition.updateFrame(node: self.backgroundNode, frame: CGRect(origin: .zero, size: size))
        transition.updateFrame(layer: self.backgroundLayer, frame: CGRect(origin: .zero, size: size))
        transition.updateFrame(node: self.expandableBackgroundNode, frame: CGRect(x: 20.0, y: 60.0, width: 10.0, height: 10.0))
        transition.updateFrame(layer: self.expandableBackgroundLayer, frame: CGRect(origin: .zero, size: self.expandableBackgroundNode.frame.size))

        let visibleProgress: CGFloat = self.expansionProgress
//        visibleProgress = max(0.0, min(1.0, visibleProgress))

        let thisState: State
        if visibleProgress == 0.0 {
            thisState = .none
        } else if visibleProgress < 1.85 {
            thisState = .swipe
        } else {
            thisState = .release
        }


        switch thisState {
        case .swipe:
            let textAttrs = NSAttributedString(string: strings.DialogList_SwipeDownForArchive, font: Font.medium(16), textColor: .white)
            self.titleNode.attributedText = textAttrs
            transition.updateFrame(node: self.titleNode, frame: self.titleNode.frame, force: true)
            transition.updateAlpha(layer: self.titleNode.layer, alpha: 1.0)
            transition.updateAlpha(layer: self.backgroundNode.layer, alpha: 1.0)
            transition.updateTransformScale(node: self.expandableBackgroundNode, scale: .init(x: 1, y: 1))
            transition.updateAlpha(layer: self.expandableBackgroundNode.layer, alpha: 0.0)

        case .release:
            let textAttrs = NSAttributedString(string: strings.DialogList_ReleaseForArchive, font: Font.medium(16), textColor: .white)
            self.titleNode.attributedText = textAttrs
            transition.updateFrame(node: self.titleNode, frame: self.titleNode.frame, force: true)
            transition.updateAlpha(layer: self.titleNode.layer, alpha: 1.0)

            transition.updateAlpha(layer: self.expandableBackgroundNode.layer, alpha: 1.0)
            transition.updateTransformScale(node: self.expandableBackgroundNode, scale: .init(x: size.width/2, y: size.width/2))

        case .none:
            transition.updateAlpha(layer: self.titleNode.layer, alpha: 0.0)
            transition.updateAlpha(layer: self.backgroundNode.layer, alpha: 0.0)
            transition.updateAlpha(layer: self.expandableBackgroundNode.layer, alpha: 0.0)
        }
        self.state = thisState
    }

    override public var height: CGFloat {
        return self.nominalHeight * self.expansionProgress
    }

    override public var clippedHeight: CGFloat {
        return self.nominalHeight * min(1.0, self.expansionProgress)
    }

    override public var nominalHeight: CGFloat {
        return navigationBarSearchContentHeight + self.additionalHeight
    }

    override public var mode: NavigationBarContentMode {
        return .expansion
    }

    enum State {
        case swipe
        case release
        case none
    }
}
