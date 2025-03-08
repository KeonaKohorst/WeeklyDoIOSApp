//
//  TaskViewController.swift
//  ToDoApp
//
//  Created by COSC Student on 2025-03-06.
//

import UIKit

class TaskViewController: UIViewController {
    
    @IBOutlet var label: UILabel!
    var databasePath = String()
    var taskName: String?
    var taskIndex: Int?
    var taskID: Int?
    var update: (() -> Void)?

    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //set up database
        let filemgr = FileManager.default
        let dirPaths = filemgr.urls(for: .documentDirectory, in: .userDomainMask)
        databasePath = dirPaths[0].appendingPathComponent("dailydo.db").path
       
        label.text = taskName
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Done Task", style: .done, target: self, action: #selector(deleteTask))

        // Do any additional setup after loading the view.
    }
    
    @objc func deleteTask(){
        guard let taskIDDB = taskID else {
            print("task index is nil")
            return
        }
        
        print("TASK index RECEIVED IS   ", taskIDDB)
        
        

        let dailyDoDB = FMDatabase(path: databasePath as String)
        if (dailyDoDB.open()) {
        let deleteSQL = "DELETE FROM Tasks WHERE id = '\(taskIDDB)'"
        let result = dailyDoDB.executeUpdate(deleteSQL, withArgumentsIn: [])
            if !result {
                //status.text = "Failed to delete student"
                print("Error: \(dailyDoDB.lastErrorMessage())")
                
            } else {
                print("Deleted task with ID: \(taskIDDB)")
                update?()
                
                //reassignUserDefaultsKeys()
                
                navigationController?.popViewController(animated: true)
                
            }
            dailyDoDB.close()
        } else {
            print("Error: \(dailyDoDB.lastErrorMessage())")
        }
        
        
    }
    
  



}
