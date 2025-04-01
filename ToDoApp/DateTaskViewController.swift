//
//  DateTaskViewController.swift
//  ToDoApp
//
//  Created by COSC Student on 2025-03-31.
//

import UIKit

class DateTaskViewController: UIViewController {
    
    @IBOutlet weak var descField: UITextView!
    @IBOutlet weak var titleField: UITextField!
    @IBOutlet weak var datePicker: UIDatePicker!
    
    var databasePath = String()
    var taskName: String?
    var taskDate: String?
    var taskID: Int?
    var taskDescription: String?
    var taskFinished: Bool = false
    var update: (() -> Void)?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        //configure style of text view
        descField.layer.borderColor = UIColor(named: "pink")!.cgColor
        descField.layer.borderWidth = 1.0
        descField.layer.cornerRadius = 5.0
        descField.layer.masksToBounds = true
        
        //set up database
        let filemgr = FileManager.default
        let dirPaths = filemgr.urls(for: .documentDirectory, in: .userDomainMask)
        databasePath = dirPaths[0].appendingPathComponent("dailydo.db").path
        
        //label.text = taskName
        titleField.text = taskName
        descField.text = taskDescription
        self.title = "Task Details"
        
        if(!taskFinished){
            navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Done Task", style: .done, target: self, action: #selector(deleteTask))
        }else{
            navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Put Back", style: .done, target: self, action: #selector(notDoneTask))
            
        }
        
    }
    
    @IBAction func datePickerChanged(_ sender: UIDatePicker){
        let date = sender.date
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm"
        let dateString = dateFormatter.string(from: date)
        taskDate = dateString
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        if self.isMovingFromParent {
            //save the changes the user made to the existing task
            //print("UPDATING TASK!")
          
            
            updateTask()
        }
    }
    
    @objc func deleteTask(){
        //this function fully deletes the task from the db
        guard let taskIDDB = taskID else {
            print("task index is nil")
            return
        }
        
        //print("TASK index RECEIVED IS   ", taskIDDB)
        
        
        
        let dailyDoDB = FMDatabase(path: databasePath as String)
        if (dailyDoDB.open()) {
            let deleteSQL = "DELETE FROM Tasks WHERE id = '\(taskIDDB)'"
            let result = dailyDoDB.executeUpdate(deleteSQL, withArgumentsIn: [])
            if !result {
                
                print("Error: \(dailyDoDB.lastErrorMessage())")
                
            } else {
                print("Deleted task with ID: \(taskIDDB)")
                update?()
                
                navigationController?.popViewController(animated: true)
                
            }
            dailyDoDB.close()
        } else {
            print("Error: \(dailyDoDB.lastErrorMessage())")
        }
        
        
    }
    
    @objc func doneTask(){
        //this function sets the finished boolean to true
        guard let taskIDDB = taskID else {
            print("task index is nil")
            return
        }
        
        //print("TASK ID in DB RECEIVED IS   ", taskIDDB)
        
        let dailyDoDB = FMDatabase(path: databasePath as String)
        if (dailyDoDB.open()) {
            let updateSQL = "UPDATE Tasks SET finished = true WHERE id = '\(taskIDDB)'"
            let result = dailyDoDB.executeUpdate(updateSQL, withArgumentsIn: [])
            if !result {
                
                print("Error: \(dailyDoDB.lastErrorMessage())")
                
            } else {
                print("Done task with ID: \(taskIDDB)")
                update?()
                
                navigationController?.popViewController(animated: true)
                
            }
            dailyDoDB.close()
        } else {
            print("Error: \(dailyDoDB.lastErrorMessage())")
        }
    }
    
    @objc func notDoneTask(){
        //this function sets the finished boolean to true
        guard let taskIDDB = taskID else {
            print("task index is nil")
            return
        }
        
        //print("TASK ID in DB RECEIVED IS   ", taskIDDB)
        
        let dailyDoDB = FMDatabase(path: databasePath as String)
        if (dailyDoDB.open()) {
            let updateSQL = "UPDATE Tasks SET finished = false WHERE id = '\(taskIDDB)'"
            let result = dailyDoDB.executeUpdate(updateSQL, withArgumentsIn: [])
            if !result {
                
                print("Error: \(dailyDoDB.lastErrorMessage())")
                
            } else {
                print("Not done task with ID: \(taskIDDB)")
                update?()
                
                navigationController?.popViewController(animated: true)
                
            }
            dailyDoDB.close()
        } else {
            print("Error: \(dailyDoDB.lastErrorMessage())")
        }
    }
    
    @objc func updateTask(){
        //save contents of the field
        guard let text = titleField.text, !text.isEmpty else {
            return
        }
        //print("UPDATING TASK ", text)
        //save task cuz not empty
        if let task = titleField.text, !task.isEmpty {
            
            let desc = descField.text ?? ""
            

            
            let dailyDoDB = FMDatabase(path: databasePath as String)
            if (dailyDoDB.open()){
                
                let date = taskDate
                var updateSQL = ""

                updateSQL = "UPDATE tasks SET taskString = '\(task)', description='\(desc)', date='\(date!)' WHERE id = \(taskID!)"
                //}
                
                let result = dailyDoDB.executeUpdate(updateSQL, withArgumentsIn: [])
                
                if !result {
                    //status.text = "Failed to add task"
                    print("Error:\(dailyDoDB.lastErrorMessage())")
                } else {
                    // Get the last inserted row ID
                    let lastInsertedID = Int(dailyDoDB.lastInsertRowId)
                    
                    print("Task UPDATED: \(task) with ID: \(lastInsertedID) and description \(desc)")
                    
                    
                    update?()
                    
                    //navigationController?.popViewController(animated: true)
                    
                }
            } else {
                print("Error: \(dailyDoDB.lastErrorMessage())")
            }
        }
        
        
        
    }
    
    @IBAction func textFieldDoneEditing(sender: UITextField){
        
        sender.resignFirstResponder()
    }
    
    @IBAction func onTapGestureRecognized1(_ sender: AnyObject){
        titleField.resignFirstResponder()
        descField.resignFirstResponder()
    }

}
