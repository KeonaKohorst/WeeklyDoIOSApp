//
//  TaskViewController.swift
//  ToDoApp
//
//  Created by COSC Student on 2025-03-06.
//

import UIKit

class TaskViewController: UIViewController {
    
    @IBOutlet var label: UILabel!
    
    @IBOutlet weak var descField: UITextView!
    @IBOutlet weak var titleField: UITextField!
    
    var databasePath = String()
    var taskName: String?
    var taskIndex: Int?
    var taskID: Int?
    var taskDescription: String?
    var update: (() -> Void)?
    
    var weekdayID: Int = 0
    var weekday: String = "Weekday"
    @IBOutlet weak var button: UIButton! //button to select the weekday
    var menuChildren: [UIMenuElement] = []
    var weekdays: [String] = ["General", "Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //configure weekdays button
        for weekday in weekdays{
            menuChildren.append(UIAction(title: weekday, handler: actionClosure))
        }
        button.menu = UIMenu(options: .displayInline, children: menuChildren)
        button.showsMenuAsPrimaryAction = true
        button.changesSelectionAsPrimaryAction = true
        
        if(weekday != "All" && weekday != "General"){
            //set the button title to the weekday
            button.setTitle(weekday, for: .normal)
        }else{
            //button.setTitle("General", for: .normal)
        }
        //set up database
        let filemgr = FileManager.default
        let dirPaths = filemgr.urls(for: .documentDirectory, in: .userDomainMask)
        databasePath = dirPaths[0].appendingPathComponent("dailydo.db").path
        
        //label.text = taskName
        titleField.text = taskName
        descField.text = taskDescription
        self.title = "Task Details"
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Done Task", style: .done, target: self, action: #selector(doneTask))
        
        // Do any additional setup after loading the view.
    }
    
    func getIdForWeekday(name: String) -> Int {
        // Get weekday from the ID
        //print("Get weekday by id: \(id)")
        let dailyDoDB = FMDatabase(path: databasePath as String)
        
        if (dailyDoDB.open()) {
            let getSQL = "SELECT id FROM Weekdays WHERE name = '\(name)'"
            if let result = dailyDoDB.executeQuery(getSQL, withArgumentsIn: []) {
                if result.next() { // move to the first row with .next()
                    let weekdayID = Int(result.int(forColumn: "id"))
                    
                    return weekdayID
                } else {
                    print("Getid for weekday function: No matching weekday id found for name \(name)")
                }
            } else {
                print("Failed to fetch id by weekday: \(dailyDoDB.lastErrorMessage())")
            }
        }else{
            print("Failed to open DB")
            
        }
        return 0
        
    }
   
    
    let actionClosure = { (action: UIAction) in print(action.title)}
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        if self.isMovingFromParent {
            //save the changes the user made to the existing task
            print("UPDATING TASK!")
            weekday = button.titleLabel!.text!
            
            updateTask()
        }
    }
    @objc func deleteTask(){
        //this function fully deletes the task from the db
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
        
        print("TASK ID in DB RECEIVED IS   ", taskIDDB)
        
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
    
    
    @objc func updateTask(){
        //save contents of the field
        guard let text = titleField.text, !text.isEmpty else {
            return
        }
        print("UPDATING TASK ", text)
        //save task cuz not empty
        if let task = titleField.text, !task.isEmpty {
            
            let desc = descField.text ?? ""
            
            //var day: String = "Weekday"
            
            //            if let selectedDay = button.title(for: .normal) {
            //                day = selectedDay  // Assign value to the variable
            //                print("EntryViewController: Weekday is \(day)")
            //            }
            
            let dailyDoDB = FMDatabase(path: databasePath as String)
            if (dailyDoDB.open()){
                
                weekdayID = getIdForWeekday(name: weekday)
                var updateSQL = ""
                //if(day != "Weekday" && day != "All"){
                
                // Get the ID for the day
                //                    let getSQL = "SELECT id FROM Weekdays WHERE name = '\(day)'"
                //                    if let result = dailyDoDB.executeQuery(getSQL, withArgumentsIn: []) {
                //                        if result.next() { // move to the first row with .next()
                //                            let weekdayID = result.int(forColumn: "id")
                //                            print("EntryViewController: Weekday id is \(weekdayID)")
                //
//                                            insertSQL = "INSERT INTO tasks (taskString, description, weekDay) VALUES ('\(task)', '\(desc)', '\(weekdayID)')"
                //                        } else {
                //                            print("No matching weekday found for \(day)")
                //                        }
                //                    } else {
                //                        print("Failed to fetch weekday ID: \(dailyDoDB.lastErrorMessage())")
                //                    }
                
                
                
                //}else{
                updateSQL = "UPDATE tasks SET taskString = '\(task)', description='\(desc)', weekday=\(weekdayID) WHERE id = \(taskID!)"
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
}
