//
//  FirestoreWrapper.swift
//  Tastopia
//
//  Created by FISH on 2020/3/10.
//  Copyright © 2020 FISH. All rights reserved.
//

import Firebase

enum Path {
    
    case collection(String)
    
    case document(String)
}

enum Action {
    
    case setData([String: Any])
    
    case fetch
}

enum Condition {
    
    case searchValue(Any, String)
    
    case containtValue(Any, String)
}

protocol Resource {
    
    var paths: [Path] { get }
    
    var action: Action { get }
    
    var conditions: [Condition] { get }
}

enum FirebaseManagerLukeError: Error {
    
    case pathError
    
    case firebaseError(String)
}

class UserManagerLuke {
    
    struct FetchUserResource: Resource {
        
        let paths: [Path] = [.collection("User"), .document("uid")]
        
        let action = Action.fetch
        
        var conditions: [Condition] = []
    }
    
    func fetchUser() {
        
//        FirebaseManagerLuke().request(resource: FetchUserResource(), completion: <#T##(Result<Data, FirebaseManagerLukeError>) -> Void#>)
    }
}

class FirebaseManagerLuke {
    
    func request(resource: Resource, completion: @escaping (Result<Data, FirebaseManagerLukeError>) -> Void) {
        
        if case .collection = resource.paths.last  {
            
            let reference = resource.colletionReference()
        
            if resource.conditions.count > 0 {
                
            } else {
                reference.getDocuments { (snapshot, error) in
                    
                    let result = snapshot!.documents.map({ $0.data() })
                    
                    do {
                        
                        let data = try JSONSerialization.data(withJSONObject: result, options: .fragmentsAllowed)
                        
                        completion(.success(data))
                        
                    } catch {
                        
                        completion(.failure(.firebaseError(error.localizedDescription)))
                    }
                }
            }
        }
    }
}

private extension Resource {
    
    func colletionReference() -> CollectionReference {
        
        var collectionReference: CollectionReference!

        var documentReference: DocumentReference!
        
        for index in 0 ..< paths.count {

            switch paths[index] {

            case .collection(let path):

                if index == 0 {

                    collectionReference = Firestore.firestore().collection(path)

                } else {

                    collectionReference = documentReference.collection(path)
                }

            case .document(let path): break

                documentReference = collectionReference.document(path)
            }
        }

        return collectionReference
    }
    
    func documentReference() -> DocumentReference {
     
        var collectionReference: CollectionReference!

        var documentReference: DocumentReference!
        
        for index in 0 ..< paths.count {

            switch paths[index] {

            case .collection(let path):

                if index == 0 {

                    collectionReference = Firestore.firestore().collection(path)

                } else {

                    collectionReference = documentReference.collection(path)
                }

            case .document(let path): break

                documentReference = collectionReference.document(path)
            }
        }
        
        return documentReference
    }
    
//    func reference() -> Query {
//
//        var reference: Query!
//
//        for index in 0 ..< paths.count {
//
//            switch paths[index] {
//
//            case .collection(let path):
//
//                if index == 0 {
//
//                    reference = Firestore.firestore().collection(path)
//
//                } else {
//
//                    if let docReference = reference as? DocumentReference {
//
//                        reference = docReference.collection(path)
//                    }
//                }
//
//            case .document(let path): break
//
//            }
//        }
//
//        return reference
//    }
}
