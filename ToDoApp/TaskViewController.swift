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
    var taskFinished: Bool = false
    var update: (() -> Void)?
    
    var weekdayID: Int = 0
    var weekday: String = "Weekday"
    @IBOutlet weak var button: UIButton! //button to select the weekday
    var menuChildren: [UIMenuElement] = []
    var weekdays: [String] = ["General", "Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]
    
    var tagID: Int = 0
    @IBOutlet weak var tagButton: UIButton! //button to select a tag
    var tagMenuChildren: [UIMenuElement] = []
    var tags: [String] = ["None", "School", "Work", "Fun", "Event", "Chore"]
    
    let idTagMap: [Int: String] = [
        0: "None",
        1: "School",
        2: "Work",
        3: "Fun",
        4: "Event",
        5: "Chore"
    ]
    
    let tagIdMap: [String: Int] = [
        "None": 0,
        "School": 1,
        "Work": 2,
        "Fun": 3,
        "Event": 4,
        "Chore": 5
    ]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if(taskFinished){ //if task is finished do not allow editing
            titleField.isEnabled = false
            descField.isEditable = false
            button.isEnabled = false
            tagButton.isEnabled = false
        }
        
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
        
        //configure tags button
        for tag in tags{
            tagMenuChildren.append(UIAction(title: tag, handler: actionClosureTag))
        }
        tagButton.menu = UIMenu(options: .displayInline, children: tagMenuChildren)
        tagButton.showsMenuAsPrimaryAction = true
        tagButton.changesSelectionAsPrimaryAction = true
        
        let tagTitle = idTagMap[tagID]
        tagButton.setTitle(tagTitle, for: .normal)
        
        
        //set up database
        let filemgr = FileManager.default
        let dirPaths = filemgr.urls(for: .documentDirectory, in: .userDomainMask)
        databasePath = dirPaths[0].appendingPathComponent("dailydo.db").path
        
        //label.text = taskName
        titleField.text = taskName
        descField.text = taskDescription
        self.title = "Task Details"
        
        if(!taskFinished){
            navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Done Task", style: .done, target: self, action: #selector(doneTask))
        }else{
            navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Put Back", style: .done, target: self, action: #selector(notDoneTask))
            
        }
        
        // Do any additional setup after loading the view.
    }
    
    let actionClosureTag = { (action: UIAction) in print(action.title)}
    
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
    
    @objc func notDoneTask(){
        //this function sets the finished boolean to true
        guard let taskIDDB = taskID else {
            print("task index is nil")
            return
        }
        
        print("TASK ID in DB RECEIVED IS   ", taskIDDB)
        
        let dailyDoDB = FMDatabase(path: databasePath as String)
        if (dailyDoDB.open()) {
            let updateSQL = "UPDATE Tasks SET finished = false WHERE id = '\(taskIDDB)'"
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
            
            let tag = tagButton.titleLabel!.text ?? "None"
            let tagID = tagIdMap[tag]

            
            let dailyDoDB = FMDatabase(path: databasePath as String)
            if (dailyDoDB.open()){
                
                weekdayID = getIdForWeekday(name: weekday)
                var updateSQL = ""

                updateSQL = "UPDATE tasks SET taskString = '\(task)', description='\(desc)', weekday=\(weekdayID), tag=\(tagID!) WHERE id = \(taskID!)"
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
