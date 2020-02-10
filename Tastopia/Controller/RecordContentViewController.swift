//
//  RecordContentViewController.swift
//  Tastopia
//
//  Created by FISH on 2020/2/5.
//  Copyright © 2020 FISH. All rights reserved.
//

import UIKit

class RecordContentViewController: UIViewController {
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var agreeRatioBackgroundView: UIView!
    @IBOutlet weak var agreeRatioView: UIView!
    @IBOutlet weak var agreeRatioViewWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var agreeRatioLabel: UILabel!
    @IBOutlet weak var recordContentCollectionView: UICollectionView!
    @IBOutlet weak var imagePageControl: UIPageControl!
    @IBOutlet weak var compositionTextView: UITextView!
    @IBOutlet weak var agreeStackView: UIStackView!
    @IBOutlet weak var agreeButton: UIButton!
    @IBOutlet weak var disagreeButton: UIButton!
    @IBOutlet weak var checkResponseButton: UIButton!
    @IBOutlet weak var responseButton: UIButton!
    
    var writing: WritingData?
    
    var responses = [ResponseData]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        recordContentCollectionView.dataSource = self
        recordContentCollectionView.delegate = self
        recordContentCollectionView.allowsSelection = false

        guard let writing = writing, let uid = UserProvider.shared.uid else { return }
        
        if writing.uid != uid {
            agreeStackView.isHidden = false
        }
        
        agreeButton.layer.maskedCorners = [.layerMinXMinYCorner, .layerMinXMaxYCorner]
        agreeButton.layer.cornerRadius = agreeButton.frame.height / 2
        if UserProvider.shared.agreeWritings.contains(writing.documentID) {
            agreeButton.setTitleColor(UIColor.SUMI, for: .normal)
            agreeButton.backgroundColor = UIColor.SAKURA
        }
        
        disagreeButton.layer.maskedCorners = [.layerMaxXMinYCorner, .layerMaxXMaxYCorner]
        disagreeButton.layer.cornerRadius = disagreeButton.frame.height / 2
        if UserProvider.shared.disagreeWritings.contains(writing.documentID) {
            disagreeButton.setTitleColor(UIColor.SUMI, for: .normal)
            disagreeButton.backgroundColor = UIColor.SAKURA
        }
        
        if writing.responseNumber > 0 {
            checkResponseButton.isHidden = false
        }
        
        titleLabel.text = writing.userName
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let date = writing.date
        dateLabel.text = dateFormatter.string(from: date)
        
        compositionTextView.text = writing.composition
        
        agreeRatioView.layer.maskedCorners = [.layerMaxXMinYCorner, .layerMaxXMaxYCorner]
        agreeRatioView.layer.cornerRadius = agreeRatioView.frame.height / 2
        
        agreeRatioBackgroundView.layer.maskedCorners = [.layerMaxXMinYCorner, .layerMaxXMaxYCorner]
        agreeRatioBackgroundView.layer.cornerRadius = agreeRatioView.frame.height / 2
        agreeRatioBackgroundView.layer.shadowColor = UIColor.SUMI?.cgColor
        agreeRatioBackgroundView.layer.shadowOffset = CGSize(width: 0, height: 5)
        agreeRatioBackgroundView.layer.shadowRadius = 5
        agreeRatioBackgroundView.layer.shadowOpacity = 0.3
        
        let agreeRatio = countAgreeRatio(agree: writing.agree, disagree: writing.disagree)
        agreeRatioLabel.text = "\(Int(agreeRatio * 100))%"
        animateAgreeRatio(ratio: CGFloat(agreeRatio))
        
        imagePageControl.numberOfPages = writing.images.count

    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        getResponse()
    }
    
    @IBAction func backButtonPressed(_ sender: Any) {
        navigationController?.popViewController(animated: true)
    }
    
    @IBAction func imagePageControlValueChanged(_ sender: UIPageControl) {
        recordContentCollectionView.scrollToItem(at: IndexPath(item: sender.currentPage, section: 0), at: .centeredHorizontally, animated: true)
    }
    
    @IBAction func agreeButtonPressed(_ sender: UIButton) {
        guard let uid = UserProvider.shared.uid, var writing = writing else { return }
        let documentID = writing.documentID
        
        if UserProvider.shared.agreeWritings.contains(documentID) {
            writing.agree -= 1
            UserProvider.shared.agreeWritings.removeAll(where: { $0 == documentID })
            FirestoreManager.shared.deleteArrayData(collection: "Users", document: uid, field: "agreeWritings", data: [documentID])
            FirestoreManager.shared.incrementData(collection: "Writings", document: documentID, field: "agree", increment: -1)
            agreeButton.setTitleColor(UIColor.HAI, for: .normal)
            agreeButton.backgroundColor = UIColor.SHIRONERI
        } else {
            writing.agree += 1
            UserProvider.shared.agreeWritings.append(documentID)
            FirestoreManager.shared.updateArrayData(collection: "Users", document: uid, field: "agreeWritings", data: [documentID])
            FirestoreManager.shared.incrementData(collection: "Writings", document: documentID, field: "agree", increment: 1)
            agreeButton.setTitleColor(UIColor.SUMI, for: .normal)
            agreeButton.backgroundColor = UIColor.SAKURA
        }
        
        if UserProvider.shared.disagreeWritings.contains(documentID) {
            writing.disagree -= 1
            UserProvider.shared.disagreeWritings.removeAll(where: { $0 == documentID })
            FirestoreManager.shared.deleteArrayData(collection: "Users", document: uid, field: "disagreeWritings", data: [documentID])
            FirestoreManager.shared.incrementData(collection: "Writings", document: documentID, field: "disagree", increment: -1)
            disagreeButton.setTitleColor(UIColor.HAI, for: .normal)
            disagreeButton.backgroundColor = UIColor.SHIRONERI
        }
        
        self.writing = writing
        let agreeRatio = countAgreeRatio(agree: writing.agree, disagree: writing.disagree)
        agreeRatioLabel.text = "\(Int(agreeRatio * 100))%"
        animateAgreeRatio(ratio: CGFloat(agreeRatio))
    }
    
    @IBAction func disagreeButtonPressed(_ sender: UIButton) {
        guard let uid = UserProvider.shared.uid, var writing = writing else { return }
        let documentID = writing.documentID
        
        if UserProvider.shared.disagreeWritings.contains(documentID) {
            writing.disagree -= 1
            UserProvider.shared.disagreeWritings.removeAll(where: { $0 == documentID })
            FirestoreManager.shared.deleteArrayData(collection: "Users", document: uid, field: "disagreeWritings", data: [documentID])
            FirestoreManager.shared.incrementData(collection: "Writings", document: documentID, field: "disagree", increment: -1)
            disagreeButton.setTitleColor(UIColor.HAI, for: .normal)
            disagreeButton.backgroundColor = UIColor.SHIRONERI
        } else {
            writing.disagree += 1
            UserProvider.shared.disagreeWritings.append(documentID)
            FirestoreManager.shared.updateArrayData(collection: "Users", document: uid, field: "disagreeWritings", data: [documentID])
            FirestoreManager.shared.incrementData(collection: "Writings", document: documentID, field: "disagree", increment: 1)
            disagreeButton.setTitleColor(UIColor.SUMI, for: .normal)
            disagreeButton.backgroundColor = UIColor.SAKURA
        }
        
        if UserProvider.shared.agreeWritings.contains(documentID) {
            writing.agree -= 1
            UserProvider.shared.agreeWritings.removeAll(where: { $0 == documentID })
            FirestoreManager.shared.deleteArrayData(collection: "Users", document: uid, field: "agreeWritings", data: [documentID])
            FirestoreManager.shared.incrementData(collection: "Writings", document: documentID, field: "agree", increment: -1)
            agreeButton.setTitleColor(UIColor.HAI, for: .normal)
            agreeButton.backgroundColor = UIColor.SHIRONERI
        }
        
        self.writing = writing
        let agreeRatio = countAgreeRatio(agree: writing.agree, disagree: writing.disagree)
        agreeRatioLabel.text = "\(Int(agreeRatio * 100))%"
        animateAgreeRatio(ratio: CGFloat(agreeRatio))
    }
    
    @IBAction func checkResponseButtonPressed(_ sender: UIButton) {
        guard let vc = storyboard?.instantiateViewController(withIdentifier: "CheckResponseViewController") as? CheckResponseViewController else { return }
        
        vc.responses = responses
        show(vc, sender: nil)
    }
    
    @IBAction func responseButtonPressed(_ sender: UIButton) {
        guard let vc = storyboard?.instantiateViewController(withIdentifier: "RecordResponseViewController") as? RecordResponseViewController else { return }
        
        vc.modalPresentationStyle = .overFullScreen
        vc.writing = writing
        vc.passResponse = { [weak self] response in
            self?.responses.append(response)
        }
        present(vc, animated: false)
    }
    
    func toggleAgree() {
        guard let uid = UserProvider.shared.uid, var writing = writing else { return }
        let documentID = writing.documentID
        
        if UserProvider.shared.agreeWritings.contains(documentID) {
            writing.agree -= 1
            UserProvider.shared.agreeWritings.removeAll(where: { $0 == documentID })
            FirestoreManager.shared.deleteArrayData(collection: "Users", document: uid, field: "agreeWritings", data: [documentID])
            FirestoreManager.shared.incrementData(collection: "Writings", document: documentID, field: "agree", increment: -1)
            agreeButton.setTitleColor(UIColor.HAI, for: .normal)
        } else {
            writing.agree += 1
            UserProvider.shared.agreeWritings.append(documentID)
            FirestoreManager.shared.updateArrayData(collection: "Users", document: uid, field: "agreeWritings", data: [documentID])
            FirestoreManager.shared.incrementData(collection: "Writings", document: documentID, field: "agree", increment: 1)
            agreeButton.setTitleColor(UIColor.red, for: .normal)
        }
        self.writing = writing
        let agreeRatio = countAgreeRatio(agree: writing.agree, disagree: writing.disagree)
        agreeRatioLabel.text = "\(Int(agreeRatio * 100))%"
        animateAgreeRatio(ratio: CGFloat(agreeRatio))
    }
    
    func countAgreeRatio(agree: Int, disagree: Int) -> Float {
         return Float(agree) / (Float(agree) + Float(disagree))
    }
    
    func animateAgreeRatio(ratio: CGFloat) {
        DispatchQueue.main.async { [weak self] in
            self?.view.layoutIfNeeded()
            let animator = UIViewPropertyAnimator(duration: 1.5, curve: .easeInOut) {
                guard let strongSelf = self else { return }
                strongSelf.agreeRatioViewWidthConstraint.constant = strongSelf.agreeRatioBackgroundView.frame.width * ratio
                strongSelf.view.layoutIfNeeded()
            }
            animator.startAnimation()
        }
    }
    
    func getResponse() {
        guard let documentID = writing?.documentID else { return }
        checkResponseButton.isEnabled = false
        ResponseProvider().getResponses(documentID: documentID) { [weak self] (result) in
            guard let strongSelf = self else { return }
            
            switch result {
            case .success(let responsesData):
                strongSelf.responses = responsesData
                strongSelf.checkResponseButton.isEnabled = true
                if strongSelf.responses.isEmpty {
                    strongSelf.checkResponseButton.isHidden = true
                } else {
                    strongSelf.checkResponseButton.isHidden = false
                }
            case .failure(let error):
                print("getResponses error: \(error)")
            }
        }
    }
}

extension RecordContentViewController: UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = view.frame.width
        return CGSize(width: width, height: width - 80)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
    
}

extension RecordContentViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        guard let writing = writing else { return 0 }
        return writing.images.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "RecordContentCollectionViewCell", for: indexPath) as? RecordContentCollectionViewCell, let writing = writing else { return UICollectionViewCell() }
        
        cell.imageView.loadImage(writing.images[indexPath.item], placeHolder: UIImage.asset(.Icon_512px_Ramen))
        return cell
    }
    
}

extension RecordContentViewController: UICollectionViewDelegate {
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        imagePageControl.currentPage = Int(scrollView.contentOffset.x / recordContentCollectionView.frame.width)
    }

}
