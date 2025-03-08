//
//  EntryViewController.swift
//  ToDoApp
//
//  Created by COSC Student on 2025-03-06.
//

import UIKit

class EntryViewController: UIViewController, UITextFieldDelegate {
    
//this is where user can enter a task and click done button
    
    @IBOutlet var field: UITextField!
    var databasePath = String()
    var update: (() -> Void)?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        //set up database
        let filemgr = FileManager.default
        let dirPaths = filemgr.urls(for: .documentDirectory, in: .userDomainMask)
        
        databasePath = dirPaths[0].appendingPathComponent("dailydo.db").path
        // Do any additional setup after loading the view.
        field.delegate = self
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Save", style: .done, target: self, action: #selector(saveTask))
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool{
        saveTask()
        return true
    }
    
    @objc func saveTask(){
        //save contents of the field
        guard let text = field.text, !text.isEmpty else {
            return
        }
        print("SAVING TASK ", text)
        //save task cuz not empty
        if let task = field.text, !task.isEmpty {
            //tasks.append(task)
            
            let dailyDoDB = FMDatabase(path: databasePath as String)
            if (dailyDoDB.open()){
                
                let insertSQL = "INSERT INTO tasks (taskString) VALUES ('\(task)')"
                
                let result = dailyDoDB.executeUpdate(insertSQL, withArgumentsIn: [])
                
                if !result {
                    //status.text = "Failed to add task"
                    print("Error:\(dailyDoDB.lastErrorMessage())")
                } else {
                    // Get the last inserted row ID
                    let lastInsertedID = Int(dailyDoDB.lastInsertRowId)

                    print("Task Added: \(task) with ID: \(lastInsertedID)")

             
                    update?()

                    field.text = ""
                    navigationController?.popViewController(animated: true)                }
            } else {
                print("Error: \(dailyDoDB.lastErrorMessage())")
            }
        }

        
       
        
        
    }
    



}
