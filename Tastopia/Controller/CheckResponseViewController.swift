//
//  CheckResponseViewController.swift
//  Tastopia
//
//  Created by FISH on 2020/2/7.
//  Copyright © 2020 FISH. All rights reserved.
//

import UIKit

class CheckResponseViewController: UIViewController {
    
    @IBOutlet weak var responseTableView: UITableView!
    
    var writing: WritingData?
    var responses = [ResponseData]()

    override func viewDidLoad() {
        super.viewDidLoad()

        responseTableView.dataSource = self
        responseTableView.delegate = self
        
        guard let writing = writing else { return }
        ResponseProvider().getResponses(documentID: writing.documentID) { [weak self] (result) in
            switch result {
            case .success(let responsesData):
                self?.responses = responsesData
                self?.responseTableView.reloadData()
            case .failure(let error):
                print("getResponses error: \(error)")
            }
        }
    }

}

extension CheckResponseViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return responses.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "CheckResponseTableViewCell", for: indexPath) as? CheckResponseTableViewCell else { return UITableViewCell() }
        
        cell.response = responses[indexPath.row]
        
        return cell
    }
    
}

extension CheckResponseViewController: UITableViewDelegate {
    
}
