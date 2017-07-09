//
//  UZTextViewCell.swift
//  Slide for Reddit
//
//  Created by Carlos Crane on 12/31/16.
//  Copyright © 2016 Haptic Apps. All rights reserved.
//

import UIKit
import reddift
import UZTextView
import ImageViewer
import TTTAttributedLabel
import RealmSwift

protocol UZTextViewCellDelegate: class {
    func pushedMoreButton(_ cell: CommentDepthCell)
    func pushedSingleTap(_ cell: CommentDepthCell)
}

class CommentDepthCell: MarginedTableViewCell, TTTAttributedLabelDelegate, UIViewControllerPreviewingDelegate {
    var moreButton: UIButton = UIButton()
    var sideView: UIView = UIView()
    var sideViewSpace: UIView = UIView()
    var topViewSpace: UIView = UIView()
    var title: TTTAttributedLabel = TTTAttributedLabel.init(frame: CGRect.zero)
    var c: UIView = UIView()
    var children: UILabel = UILabel()
    var menu: UIView = UIView()
    var comment:RComment?
    var depth:Int = 0
    
    func attributedLabel(_ label: TTTAttributedLabel!, didLongPressLinkWith url: URL!, at point: CGPoint) {
        if parent != nil{
            let sheet = UIAlertController(title: url.absoluteString, message: nil, preferredStyle: .actionSheet)
            sheet.addAction(
                UIAlertAction(title: "Close", style: .cancel) { (action) in
                    sheet.dismiss(animated: true, completion: nil)
                }
            )
            let open = OpenInChromeController.init()
            if(open.isChromeInstalled()){
                sheet.addAction(
                    UIAlertAction(title: "Open in Chrome", style: .default) { (action) in
                        _ = open.openInChrome(url, callbackURL: nil, createNewTab: true)
                    }
                )
            }
            sheet.addAction(
                UIAlertAction(title: "Open in Safari", style: .default) { (action) in
                    UIApplication.shared.open(url, options: [:], completionHandler: nil)
                    sheet.dismiss(animated: true, completion: nil)
                }
            )
            sheet.addAction(
                UIAlertAction(title: "Open", style: .default) { (action) in
                    /* let controller = WebViewController(nibName: nil, bundle: nil)
                     controller.url = url
                     let nav = UINavigationController(rootViewController: controller)
                     self.present(nav, animated: true, completion: nil)*/
                }
            )
            sheet.addAction(
                UIAlertAction(title: "Copy URL", style: .default) { (action) in
                    UIPasteboard.general.setValue(url, forPasteboardType: "public.url")
                    sheet.dismiss(animated: true, completion: nil)
                }
            )
            parent?.present(sheet, animated: true, completion: nil)
        }
    }
    
    var parent: CommentViewController?
    
    func attributedLabel(_ label: TTTAttributedLabel!, didSelectLinkWith url: URL!) {
        parent?.doShow(url: url)
    }
    
    func upvote(){
        
    }
    
    var delegate: UZTextViewCellDelegate? = nil
    var content: Object? = nil
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        
        self.title = TTTAttributedLabel(frame: CGRect(x: 0, y: 0, width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude))
        title.numberOfLines = 0
        title.font = FontGenerator.fontOfSize(size: 12, submission: false)
        title.isUserInteractionEnabled = true
        title.delegate = self
        title.textColor = ColorUtil.fontColor
        
        self.children = UILabel(frame: CGRect(x: 0, y: 0, width: CGFloat.greatestFiniteMagnitude, height: 15))
        children.numberOfLines = 1
        children.font = FontGenerator.boldFontOfSize(size: 12, submission: false)
        children.textColor = UIColor.white
        children.layer.shadowOffset = CGSize(width: 0, height: 0)
        children.layer.shadowOpacity = 0.4
        children.layer.shadowRadius = 4
        let padding = UIEdgeInsets(top: 2, left: 2, bottom: 2, right: 2)
        
        
        
        self.moreButton = UIButton(frame: CGRect(x: 0, y: 0, width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude))
        self.menu = UIView(frame: CGRect(x: 0, y: 0, width: CGFloat.greatestFiniteMagnitude, height: 0))
        
        self.sideView = UIView(frame: CGRect(x: 0, y: 0, width: 4, height: CGFloat.greatestFiniteMagnitude))
        self.sideViewSpace = UIView(frame: CGRect(x: 0, y: 0, width: 4, height: CGFloat.greatestFiniteMagnitude))
        self.topViewSpace = UIView(frame: CGRect(x: 0, y: 0, width: CGFloat.greatestFiniteMagnitude, height: 4))
        
        self.c = children.withPadding(padding: padding)
        c.alpha = 0
        c.backgroundColor = ColorUtil.accentColorForSub(sub: "")
        c.layer.cornerRadius = 4
        c.clipsToBounds = true
        
        moreButton.translatesAutoresizingMaskIntoConstraints = false
        sideView.translatesAutoresizingMaskIntoConstraints = false
        sideViewSpace.translatesAutoresizingMaskIntoConstraints = false
        topViewSpace.translatesAutoresizingMaskIntoConstraints = false
        title.translatesAutoresizingMaskIntoConstraints = false
        menu.translatesAutoresizingMaskIntoConstraints = false
        children.translatesAutoresizingMaskIntoConstraints = false
        c.translatesAutoresizingMaskIntoConstraints = false
        
        self.contentView.addSubview(moreButton)
        self.contentView.addSubview(sideView)
        self.contentView.addSubview(sideViewSpace)
        self.contentView.addSubview(topViewSpace)
        self.contentView.addSubview(title)
        self.contentView.addSubview(menu)
        self.contentView.addSubview(c)
        
        moreButton.addTarget(self, action: #selector(CommentDepthCell.pushedMoreButton(_:)), for: UIControlEvents.touchUpInside)
        
       //todo maybe let tap = UILongPressGestureRecognizer(target: self, action: #selector(self.more))
      //  tap.cancelsTouchesInView = false
      //  self.contentView.addGestureRecognizer(tap)
        
        let tap2 = UISwipeGestureRecognizer(target: self, action: #selector(self.vote))
        tap2.direction = .right
         self.contentView.addGestureRecognizer(tap2)

        let tapGestureRecognizer = UITapGestureRecognizer.init(target: self, action: #selector(self.pushedSingleTap(_:)))
        tapGestureRecognizer.cancelsTouchesInView = false
        tapGestureRecognizer.delegate = self
        self.title.addGestureRecognizer(tapGestureRecognizer)

        self.contentView.backgroundColor = ColorUtil.foregroundColor
        sideViewSpace.backgroundColor = ColorUtil.backgroundColor
        topViewSpace.backgroundColor = ColorUtil.backgroundColor
        
        self.clipsToBounds = true
    }
    
    override func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        if(gestureRecognizer.view == self.title){
            return self.title.link(at: touch.location(in: self.title)) == nil
        }
        return true
    }
    func vote(){
        if(content is RComment){
        let current = ActionStates.getVoteDirection(s: comment!)
        var dir = (current == VoteDirection.none) ? VoteDirection.up : VoteDirection.none
        var direction = dir
        switch(ActionStates.getVoteDirection(s: comment!)){
        case .up:
            if(dir == .up){
                direction = .none
            }
            break
        case .down:
            if(dir == .down){
                direction = .none
            }
            break
        default:
            break
        }
        do {
            try parent?.session?.setVote(direction, name: (comment!.name), completion: { (result) -> Void in
                switch result {
                case .failure(let error):
                    print(error.description)
                case .success(let check): break
                }
            })
        } catch { print(error) }
        ActionStates.setVoteDirection(s: comment!, direction: direction)
        refresh(comment: content as! RComment, submissionAuthor: savedAuthor, text: cellContent!)
        }
    }
    
    func more(_ par: CommentViewController){
        let alertController = UIAlertController(title: "Comment by /u/\(comment!.author)", message: "", preferredStyle: .actionSheet)
        
        
        let cancelActionButton: UIAlertAction = UIAlertAction(title: "Cancel", style: .cancel) { action -> Void in
            print("Cancel")
        }
        
        alertController.addAction(cancelActionButton)
        
        let profile: UIAlertAction = UIAlertAction(title: "/u/\(comment!.author)'s profile", style: .default) { action -> Void in
            par.show(ProfileViewController.init(name: self.comment!.author), sender: self)
        }
        
        alertController.addAction(profile)
        if(AccountController.isLoggedIn){
            
            let save: UIAlertAction = UIAlertAction(title: "Save", style: .default) { action -> Void in
                par.saveComment(self.comment!)
            }
            
            alertController.addAction(save)
        }
        
        let report: UIAlertAction = UIAlertAction(title: "Report", style: .default) { action -> Void in
            par.report(self.comment!)
        }
        
        alertController.addAction(report)
        
        
        par.parent?.present(alertController, animated: true, completion: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    var sideConstraint: [NSLayoutConstraint]?
    
    func collapse(childNumber: Int){
        children.text = "+\(childNumber)"
        UIView.animate(withDuration: 0.4, delay: 0.0, options:
            UIViewAnimationOptions.curveEaseOut, animations: {
                self.c.alpha = 1
        }, completion: { finished in
        })
        
    }
    
    func expand(){
        UIView.animate(withDuration: 0.4, delay: 0.0, options:
            UIViewAnimationOptions.curveEaseOut, animations: {
                self.c.alpha = 0
        }, completion: { finished in
        })
        
    }
    
    func updateDepthConstraints(){
        if(sideConstraint != nil){
            self.contentView.removeConstraints(sideConstraint!)
        }
        let metrics=["marginTop": marginTop, "nmarginTop": -marginTop, "horizontalMargin":75,"top":0,"bottom":0,"separationBetweenLabels":0,"labelMinHeight":75, "sidewidth":4*(depth ), "width":sideWidth]
        let views=["title": title, "menu":menu, "topviewspace":topViewSpace, "more": moreButton, "side":sideView, "cell":self.contentView, "sideviewspace":sideViewSpace] as [String : Any]
        
        
        sideConstraint = NSLayoutConstraint.constraints(withVisualFormat: "H:|-(-8)-[sideviewspace(sidewidth)]-0-[side(width)]",
                                                        options: NSLayoutFormatOptions(rawValue: 0),
                                                        metrics: metrics,
                                                        views: views)
        sideConstraint!.append(contentsOf: NSLayoutConstraint.constraints(withVisualFormat: "H:|-(-8)-[sideviewspace(sidewidth)]-0-[side(width)]-8-[title]-2-|",
                                                                          options: NSLayoutFormatOptions(rawValue: 0),
                                                                          metrics: metrics,
                                                                          views: views))
        self.contentView.addConstraints(sideConstraint!)
    }
    
    override func updateConstraints() {
        super.updateConstraints()
        
        let metrics=["marginTop": marginTop, "nmarginTop": -marginTop, "horizontalMargin":75,"top":0,"bottom":0,"separationBetweenLabels":0,"labelMinHeight":75, "sidewidth":4*(depth ), "width":sideWidth]
        let views=["title": title, "children":c, "menu":menu, "topviewspace":topViewSpace, "more": moreButton, "side":sideView, "cell":self.contentView, "sideviewspace":sideViewSpace] as [String : Any]
        
        
        
        contentView.bounds = CGRect.init(x: 0,y: 0, width: contentView.frame.size.width , height: contentView.frame.size.height + CGFloat(marginTop))
        
        var constraint:[NSLayoutConstraint] = []
        
        constraint.append(contentsOf: NSLayoutConstraint.constraints(withVisualFormat: "H:|-(-8)-[sideviewspace]-0-[side]-8-[title]-2-|",
                                                                     options: NSLayoutFormatOptions(rawValue: 0),
                                                                     metrics: metrics,
                                                                     views: views))
        constraint.append(contentsOf: NSLayoutConstraint.constraints(withVisualFormat: "H:|-0-[topviewspace]-0-|",
                                                                     options: NSLayoutFormatOptions(rawValue: 0),
                                                                     metrics: metrics,
                                                                     views: views))
        constraint.append(contentsOf: NSLayoutConstraint.constraints(withVisualFormat: "H:|-0-[menu]-0-|",
                                                                     options: NSLayoutFormatOptions(rawValue: 0),
                                                                     metrics: metrics,
                                                                     views: views))
        
        constraint.append(contentsOf:NSLayoutConstraint.constraints(withVisualFormat: "V:|-0-[topviewspace(marginTop)]-4-[title]-4-|",
                                                                    options: NSLayoutFormatOptions(rawValue: 0),
                                                                    metrics: metrics,
                                                                    views: views))
        
        
        constraint.append(contentsOf:NSLayoutConstraint.constraints(withVisualFormat: "V:|-2-[more]-2-|",
                                                                    options: NSLayoutFormatOptions(rawValue: 0),
                                                                    metrics: metrics,
                                                                    views: views))
        
        constraint.append(contentsOf:NSLayoutConstraint.constraints(withVisualFormat: "V:|-4-[children]",
                                                                    options: NSLayoutFormatOptions(rawValue: 0),
                                                                    metrics: metrics,
                                                                    views: views))
        constraint.append(contentsOf:NSLayoutConstraint.constraints(withVisualFormat: "H:[children]-4-|",
                                                                    options: NSLayoutFormatOptions(rawValue: 0),
                                                                    metrics: metrics,
                                                                    views: views))
        
        constraint.append(contentsOf:NSLayoutConstraint.constraints(withVisualFormat: "V:|-0-[topviewspace(marginTop)]-(nmarginTop)-[side]-(-1)-|",
                                                                    options: NSLayoutFormatOptions(rawValue: 0),
                                                                    metrics: metrics,
                                                                    views: views))
        constraint.append(contentsOf:NSLayoutConstraint.constraints(withVisualFormat: "V:|-0-[topviewspace(marginTop)]-(nmarginTop)-[sideviewspace]-0-|",
                                                                    options: NSLayoutFormatOptions(rawValue: 0),
                                                                    metrics: metrics,
                                                                    views: views))
        
        
        self.contentView.addConstraints(constraint)
        updateDepthConstraints()
        
        
    }
    var sideWidth: Int = 0
    var marginTop: Int = 0
    
    func setMore(more: RMore, depth: Int){
        self.depth = depth
        loading = false
        c.alpha = 0
        self.contentView.backgroundColor = ColorUtil.foregroundColor
        if (depth - 1 > 0) {
            sideWidth = 4
            marginTop = 1
            let i22 = depth - 2;
            if(SettingValues.disableColor){
                if (i22 % 5 == 0) {
                    sideView.backgroundColor = GMColor.grey100Color()
                } else if (i22 % 4 == 0) {
                    sideView.backgroundColor = GMColor.grey200Color()
                } else if (i22 % 3 == 0) {
                    sideView.backgroundColor = GMColor.grey300Color()
                } else if (i22 % 2 == 0) {
                    sideView.backgroundColor = GMColor.grey400Color()
                } else {
                    sideView.backgroundColor = GMColor.grey500Color()
                }
            } else {
                if (i22 % 5 == 0) {
                    sideView.backgroundColor = GMColor.blue500Color()
                } else if (i22 % 4 == 0) {
                    sideView.backgroundColor = GMColor.green500Color()
                } else if (i22 % 3 == 0) {
                    sideView.backgroundColor = GMColor.yellow500Color()
                } else if (i22 % 2 == 0) {
                    sideView.backgroundColor = GMColor.orange500Color()
                } else {
                    sideView.backgroundColor = GMColor.red500Color()
                }
            }
        } else {
            marginTop = 8
            sideWidth = 0
        }
        
        var attr = NSMutableAttributedString()
        if(more.children.isEmpty){
            attr = NSMutableAttributedString(string: "Continue this thread")
        } else {
            attr = NSMutableAttributedString(string: "Load \(more.count) more")
        }
        let font = FontGenerator.fontOfSize(size: 16, submission: false)
        let attr2 = attr.reconstruct(with: font, color: ColorUtil.fontColor, linkColor: .white)
        title.setText(attr2)
        updateDepthConstraints()
    }
    
    var numberOfDots = 3
    var loading = false
    func animateMore() {
        loading = true
        let attr = NSMutableAttributedString(string: "Loading...")
        let font = FontGenerator.fontOfSize(size: 16, submission: false)
        let attr2 = NSMutableAttributedString(attributedString: attr.reconstruct(with: font, color: ColorUtil.fontColor, linkColor: UIColor.blue))
        
        
        title.setText(attr2)
        
        /* possibly todo var timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { (timer) in
         print("Firing")
         let range = NSMakeRange(attr2.length - self.numberOfDots, self.numberOfDots)
         attr2.addAttribute(NSForegroundColorAttributeName, value: UIColor.clear, range: range)
         
         self.textView.attributedString = attr2
         self.numberOfDots -= 1
         if self.numberOfDots < 0 {
         self.numberOfDots = 3
         }
         if(self.loading == false){
         timer.invalidate()
         }
         }*/
    }
    
    
    func setComment(comment: RComment, depth: Int, parent: CommentViewController, hiddenCount: Int, date: Double, author: String?, text: NSAttributedString){
        self.comment = comment
        self.cellContent = text
        self.contentView.backgroundColor = ColorUtil.foregroundColor
        loading = false
        if(self.parent == nil){
            self.parent = parent
        }
        
        if(date != 0 && date < Double(comment.created.timeIntervalSince1970 )){
            setIsNew(sub: comment.subreddit)
        }
        
        if(hiddenCount > 0){
            c.alpha = 1
            children.text = "+\(hiddenCount)"
        } else {
            c.alpha = 0
        }
        
        self.depth = depth
        if (depth - 1 > 0) {
            sideWidth = 4
            marginTop = 1
            let i22 = depth - 2;
            if(SettingValues.disableColor){
                if (i22 % 5 == 0) {
                    sideView.backgroundColor = GMColor.grey100Color()
                } else if (i22 % 4 == 0) {
                    sideView.backgroundColor = GMColor.grey200Color()
                } else if (i22 % 3 == 0) {
                    sideView.backgroundColor = GMColor.grey300Color()
                } else if (i22 % 2 == 0) {
                    sideView.backgroundColor = GMColor.grey400Color()
                } else {
                    sideView.backgroundColor = GMColor.grey500Color()
                }
            } else {
                if (i22 % 5 == 0) {
                    sideView.backgroundColor = GMColor.blue500Color()
                } else if (i22 % 4 == 0) {
                    sideView.backgroundColor = GMColor.green500Color()
                } else if (i22 % 3 == 0) {
                    sideView.backgroundColor = GMColor.yellow500Color()
                } else if (i22 % 2 == 0) {
                    sideView.backgroundColor = GMColor.orange500Color()
                } else {
                    sideView.backgroundColor = GMColor.red500Color()
                }
            }
        } else {
            //marginTop = 8
            marginTop = 1
            sideWidth = 0
        }
        
        
        refresh(comment: comment, submissionAuthor: author, text: text)
        
        if(!registered){
            parent.registerForPreviewing(with: self, sourceView: title)
            registered = true
        }
        updateDepthConstraints()
        
    }
    
    var cellContent: NSAttributedString?
    
    var savedAuthor: String = ""
    func refresh(comment: RComment, submissionAuthor: String?, text: NSAttributedString){
        var color: UIColor
        
        savedAuthor = submissionAuthor!
        
        switch(ActionStates.getVoteDirection(s: comment)){
        case .down:
            color = ColorUtil.downvoteColor
            break
        case .up:
            color = ColorUtil.upvoteColor
            break
        default:
            color = ColorUtil.fontColor
            break
        }
        
        
        let scoreString = NSMutableAttributedString(string: ((comment.scoreHidden ? "[score hidden]" : "\(getScoreText(comment: comment))") + (comment.controversiality > 0 ? "†" : "" )), attributes: [NSForegroundColorAttributeName: color])
        
        let endString = NSMutableAttributedString(string:"  •  \(DateFormatter().timeSince(from: comment.created, numericDates: true))" + (comment.isEdited ? ("(edit \(DateFormatter().timeSince(from: comment.edited, numericDates: true)))") : ""),  attributes: [NSForegroundColorAttributeName: ColorUtil.fontColor])
        
        
        let authorString = NSMutableAttributedString(string: "\u{00A0}\(comment.author)\u{00A0}", attributes: [NSFontAttributeName: FontGenerator.boldFontOfSize(size: 12, submission: false), NSForegroundColorAttributeName: ColorUtil.fontColor])
        let flairTitle = NSMutableAttributedString.init(string: "\u{00A0}\(comment.flair)\u{00A0}", attributes: [kTTTBackgroundFillColorAttributeName: ColorUtil.backgroundColor, NSFontAttributeName: FontGenerator.boldFontOfSize(size: 12, submission: false), NSForegroundColorAttributeName: ColorUtil.fontColor, kTTTBackgroundFillPaddingAttributeName: UIEdgeInsets.init(top: 1, left: 1, bottom: 1, right: 1), kTTTBackgroundCornerRadiusAttributeName: 3])
        let pinned = NSMutableAttributedString.init(string: "\u{00A0}PINNED\u{00A0}", attributes: [kTTTBackgroundFillColorAttributeName: GMColor.green500Color(), NSFontAttributeName: FontGenerator.boldFontOfSize(size: 12, submission: false), NSForegroundColorAttributeName: UIColor.white, kTTTBackgroundFillPaddingAttributeName: UIEdgeInsets.init(top: 1, left: 1, bottom: 1, right: 1), kTTTBackgroundCornerRadiusAttributeName: 3])
        let gilded = NSMutableAttributedString.init(string: "\u{00A0}x\(comment.gilded) ", attributes: [NSFontAttributeName: FontGenerator.boldFontOfSize(size: 12, submission: false)])
        
        let spacer = NSMutableAttributedString.init(string: "  ")
        var userColor = ColorUtil.getColorForUser(name: comment.author)
        if (comment.distinguished == "admin") {
            
            authorString.addAttributes([kTTTBackgroundFillColorAttributeName: UIColor.init(hexString: "#E57373"), NSFontAttributeName: FontGenerator.boldFontOfSize(size: 12, submission: false), NSForegroundColorAttributeName: UIColor.white, kTTTBackgroundFillPaddingAttributeName: UIEdgeInsets.init(top: 1, left: 1, bottom: 1, right: 1), kTTTBackgroundCornerRadiusAttributeName: 3], range: NSRange.init(location: 0, length: authorString.length))
        } else if (comment.distinguished == "special") {
            authorString.addAttributes([kTTTBackgroundFillColorAttributeName: UIColor.init(hexString: "#F44336"), NSFontAttributeName: FontGenerator.boldFontOfSize(size: 12, submission: false), NSForegroundColorAttributeName: UIColor.white, kTTTBackgroundFillPaddingAttributeName: UIEdgeInsets.init(top: 1, left: 1, bottom: 1, right: 1), kTTTBackgroundCornerRadiusAttributeName: 3], range: NSRange.init(location: 0, length: authorString.length))
        } else if (comment.distinguished == "moderator") {
            authorString.addAttributes([kTTTBackgroundFillColorAttributeName: UIColor.init(hexString: "#81C784"), NSFontAttributeName: FontGenerator.boldFontOfSize(size: 12, submission: false), NSForegroundColorAttributeName: UIColor.white, kTTTBackgroundFillPaddingAttributeName: UIEdgeInsets.init(top: 1, left: 1, bottom: 1, right: 1), kTTTBackgroundCornerRadiusAttributeName: 3], range: NSRange.init(location: 0, length: authorString.length))
        } else if (AccountController.currentName == comment.author) {
            authorString.addAttributes([kTTTBackgroundFillColorAttributeName: UIColor.init(hexString: "#FFB74D"), NSFontAttributeName: FontGenerator.boldFontOfSize(size: 12, submission: false), NSForegroundColorAttributeName: UIColor.white, kTTTBackgroundFillPaddingAttributeName: UIEdgeInsets.init(top: 1, left: 1, bottom: 1, right: 1), kTTTBackgroundCornerRadiusAttributeName: 3], range: NSRange.init(location: 0, length: authorString.length))
        } else if(submissionAuthor != nil && comment.author == submissionAuthor) {
            authorString.addAttributes([kTTTBackgroundFillColorAttributeName: UIColor.init(hexString: "#64B5F6"), NSFontAttributeName: FontGenerator.boldFontOfSize(size: 12, submission: false), NSForegroundColorAttributeName: UIColor.white, kTTTBackgroundFillPaddingAttributeName: UIEdgeInsets.init(top: 1, left: 1, bottom: 1, right: 1), kTTTBackgroundCornerRadiusAttributeName: 3], range: NSRange.init(location: 0, length: authorString.length))
        } else if (userColor != ColorUtil.baseColor) {
            authorString.addAttributes([kTTTBackgroundFillColorAttributeName: userColor, NSFontAttributeName: FontGenerator.boldFontOfSize(size: 12, submission: false), NSForegroundColorAttributeName: UIColor.white, kTTTBackgroundFillPaddingAttributeName: UIEdgeInsets.init(top: 1, left: 1, bottom: 1, right: 1), kTTTBackgroundCornerRadiusAttributeName: 3], range: NSRange.init(location: 0, length: authorString.length))
        }
        
        let infoString = NSMutableAttributedString(string: "\u{00A0}")
        infoString.append(authorString)
        
        let tag = ColorUtil.getTagForUser(name: comment.author)
        if(!tag.isEmpty){
            let tagString = NSMutableAttributedString(string: "\u{00A0}\(tag)\u{00A0}", attributes: [NSFontAttributeName: FontGenerator.boldFontOfSize(size: 12, submission: false), NSForegroundColorAttributeName: ColorUtil.fontColor])
            tagString.addAttributes([kTTTBackgroundFillColorAttributeName: UIColor(rgb: 0x2196f3), NSFontAttributeName: FontGenerator.boldFontOfSize(size: 12, submission: false), NSForegroundColorAttributeName: UIColor.white, kTTTBackgroundFillPaddingAttributeName: UIEdgeInsets.init(top: 1, left: 1, bottom: 1, right: 1), kTTTBackgroundCornerRadiusAttributeName: 3], range: NSRange.init(location: 0, length: authorString.length))
            infoString.append(spacer)
            infoString.append(tagString)
        }

        infoString.append(NSAttributedString(string:"  •  ", attributes: [NSFontAttributeName: FontGenerator.fontOfSize(size: 12, submission: false), NSForegroundColorAttributeName: ColorUtil.fontColor]))
        infoString.append(scoreString)
        infoString.append(endString)
        
        if(!comment.flair.isEmpty){
            infoString.append(spacer)
            infoString.append(flairTitle)
        }
        
        if(comment.pinned){
            infoString.append(spacer)
            infoString.append(pinned)
        }
        if(comment.gilded > 0){
            infoString.append(spacer)
            let gild = NSMutableAttributedString.init(string: "G", attributes: [kTTTBackgroundFillColorAttributeName: GMColor.amber500Color(), NSFontAttributeName: FontGenerator.boldFontOfSize(size: 12, submission: false), NSForegroundColorAttributeName: UIColor.white, kTTTBackgroundFillPaddingAttributeName: UIEdgeInsets.init(top: 1, left: 1, bottom: 1, right: 1), kTTTBackgroundCornerRadiusAttributeName: 3])
            infoString.append(gild)
            if(comment.gilded > 1){
                infoString.append(gilded)
            }
        }
        
        infoString.append(NSAttributedString.init(string: "\n"))
        infoString.append(text)

        if(!setLinkAttrs){
        let activeLinkAttributes = NSMutableDictionary(dictionary: title.activeLinkAttributes)
        activeLinkAttributes[NSForegroundColorAttributeName] = ColorUtil.accentColorForSub(sub: comment.subreddit)
        title.activeLinkAttributes = activeLinkAttributes as NSDictionary as! [AnyHashable: Any]
        title.linkAttributes = activeLinkAttributes as NSDictionary as! [AnyHashable: Any]
            setLinkAttrs = true
        }
        title.setText(infoString)

    }
    
    var setLinkAttrs = false
    
    func setIsContext(){
        self.contentView.backgroundColor = GMColor.yellow500Color().withAlphaComponent(0.5)
    }
    
    func setIsNew(sub: String){
        self.contentView.backgroundColor = ColorUtil.getColorForSub(sub: sub).withAlphaComponent(0.5)
    }

    
    func getScoreText(comment: RComment) -> Int {
        var submissionScore = comment.score
        switch (ActionStates.getVoteDirection(s: comment)) {
        case .up:
            if(comment.likes != .up){
                if(comment.likes == .down){
                    submissionScore += 1
                }
                submissionScore += 1
            }
            break
        case .down:
            if(comment.likes != .down){
                if(comment.likes == .up){
                    submissionScore -= 1
                }
                submissionScore -= 1
            }
            break
        case .none:
            if(comment.likes == .up && comment.author == AccountController.currentName){
                submissionScore -= 1
            }
        }
        return submissionScore
    }
    
    var registered:Bool = false
    
    func previewingContext(_ previewingContext: UIViewControllerPreviewing,
                           viewControllerForLocation location: CGPoint) -> UIViewController? {
        
        let locationInTextView = title.convert(location, to: title)
        
        if let (url, rect) = getInfo(locationInTextView: locationInTextView) {
            previewingContext.sourceRect = title.convert(rect, from: title)
            if let controller = parent?.getControllerForUrl(baseUrl: url){
                return controller
            }
        }
        
        return nil
    }
    
    func getInfo(locationInTextView: CGPoint) -> (URL, CGRect)? {
        if let attr = title.link(at: locationInTextView) {
            if let url = attr.result.url {
                return (url, title.bounds)
            }
            
        }
        return nil
    }
    
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, commit viewControllerToCommit: UIViewController) {
        if(viewControllerToCommit is GalleryViewController || viewControllerToCommit is YouTubeViewController){
            parent?.presentImageGallery(viewControllerToCommit as! GalleryViewController)
        } else {
            parent?.show(viewControllerToCommit, sender: parent )
        }
    }
    
    var menuShowing: Bool = false
        
    func pushedMoreButton(_ sender: AnyObject?) {
        if let delegate = self.delegate {
            delegate.pushedMoreButton(self)
        }
    }
    
    func longPressed(_ sender: AnyObject?) {
        if self.delegate != nil {
        }
    }
    
    func pushedSingleTap(_ sender: AnyObject?) {
        if let delegate = self.delegate {
            delegate.pushedSingleTap(self)
        }
    }
    
    class func margin() -> UIEdgeInsets {
        return UIEdgeInsetsMake(4, 0, 2, 0)
    }
    
}
extension UIView {
    func withPadding(padding: UIEdgeInsets) -> UIView {
        let container = UIView()
        self.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(self)
        container.addConstraints(NSLayoutConstraint.constraints(
            withVisualFormat: "|-(\(padding.left))-[view]-(\(padding.right))-|"
            , options: [], metrics: nil, views: ["view": self]))
        container.addConstraints(NSLayoutConstraint.constraints(
            withVisualFormat: "V:|-(\(padding.top)@999)-[view]-(\(padding.bottom)@999)-|",
            options: [], metrics: nil, views: ["view": self]))
        return container
    }
}
