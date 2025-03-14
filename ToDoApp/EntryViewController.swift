//
//  EntryViewController.swift
//  ToDoApp
//
//  Created by COSC Student on 2025-03-06.
//

import UIKit

class EntryViewController: UIViewController, UITextFieldDelegate {
    
//this is where user can enter a task and click save button
    
    
    @IBOutlet var field: UITextField!
    @IBOutlet var descField: UITextView!
   
    var databasePath = String()
    var update: (() -> Void)?
    
    var weekday: String = "Weekday"
    @IBOutlet weak var button: UIButton! //button to select the weekday
    //let button = UIButton(primaryAction: nil)
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
        
        if(weekday != "All"){
            //set the button title to the weekday
            button.setTitle(weekday, for: .normal)
        }else{
            button.setTitle("General", for: .normal)
        }
        
        
        
        //set up database connection
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
    
    let actionClosure = { (action: UIAction) in print(action.title)}
    
    @objc func saveTask(){
        //save contents of the field
        guard let text = field.text, !text.isEmpty else {
            return
        }
        print("SAVING TASK ", text)
        //save task cuz not empty
        if let task = field.text, !task.isEmpty {
            
            let desc = descField.text ?? ""
            
            var day: String = "General"
            
            if let selectedDay = button.title(for: .normal) {
                day = selectedDay  // Assign value to the variable
                print("EntryViewController: Weekday is \(day)")
            }
            
            let dailyDoDB = FMDatabase(path: databasePath as String)
            if (dailyDoDB.open()){
                
                var insertSQL = ""
                if(day != "General"){

                    // Get the ID for the day
                    let getSQL = "SELECT id FROM Weekdays WHERE name = '\(day)'"
                    if let result = dailyDoDB.executeQuery(getSQL, withArgumentsIn: []) {
                        if result.next() { // move to the first row with .next()
                            let weekdayID = result.int(forColumn: "id")
                            print("EntryViewController: Weekday id is \(weekdayID)")
                            
                            //get the latest index in list for the day
                            let indexInList = getLatestIndexInListForDay(day: day)
                            let newIndexInList = indexInList + 1
                            
                            insertSQL = "INSERT INTO tasks (taskString, description, weekDay, indexInList) VALUES ('\(task)', '\(desc)', \(weekdayID), \(newIndexInList));"
                        } else {
                            print("No matching weekday found for \(day)")
                        }
                    } else {
                        print("Failed to fetch weekday ID: \(dailyDoDB.lastErrorMessage())")
                    }

                    
               
                }else{
                    let indexInList = getLatestIndexInListForGeneral(day: "General")
                    let newIndexInList = indexInList + 1
                    print("The indexInList was \(indexInList) ad the new one is \(newIndexInList)")
                    insertSQL = "INSERT INTO tasks (taskString, description, weekday, indexInList) VALUES ('\(task)', '\(desc)', 0, \(newIndexInList));"
                }
                
                let result = dailyDoDB.executeUpdate(insertSQL, withArgumentsIn: [])
                
                if !result {
                    //status.text = "Failed to add task"
                    print("Error:\(dailyDoDB.lastErrorMessage())")
                } else {
                    // Get the last inserted row ID
                    let lastInsertedID = Int(dailyDoDB.lastInsertRowId)

                    print("Task Added: \(task) with ID: \(lastInsertedID) and description \(desc) and weekday \(day)")

             
                    update?()

                    field.text = ""
                    descField.text = ""
                    navigationController?.popViewController(animated: true)
                    
                }
            } else {
                print("Error: \(dailyDoDB.lastErrorMessage())")
            }
        }

    }
    
    func getLatestIndexInListForDay(day: String) -> Int {
        print("-----GET LATEST INDEX FOR DAY-----")
        let dailyDoDB = FMDatabase(path: databasePath as String)
        
        if (dailyDoDB.open()) {
            let getSQL = "SELECT MAX(t.indexInList) AS indexInList FROM tasks t, weekdays w WHERE w.name= '\(day)' AND w.id = t.weekday;"
            if let result = dailyDoDB.executeQuery(getSQL, withArgumentsIn: []) {
                if result.next() {
                    let index = Int(result.int(forColumn: "indexInList"))
                    print("The latest index in list for the day \(day) is \(index)")
                    return index
                } else {
                    print("Entry: Get index in list for day function: No matching name for \(day)")
                }
            } else {
                print("Entry: Failed to fetch index in list by day: \(dailyDoDB.lastErrorMessage())")
            }
        }else{
            print("Failed to open DB")
            
        }
        print("The latest index in list for the day \(day) is 0")
        return 0
        
    }
    
    func getLatestIndexInListForGeneral(day: String) -> Int {
        print("-----GET LATEST INDEX FOR GENERAL DAY-----")
        let dailyDoDB = FMDatabase(path: databasePath as String)
        
        if (dailyDoDB.open()) {
            let getSQL = "SELECT MAX(t.indexInList) AS indexInList FROM tasks t WHERE t.weekday = 0;"
            if let result = dailyDoDB.executeQuery(getSQL, withArgumentsIn: []) {
                if result.next() {
                    let index = Int(result.int(forColumn: "indexInList"))
                    print("The latest index in list for the day \(day) is \(index)")
                    return index
                } else {
                    print("Entry: Get index in list for day function: No matching name for \(day)")
                }
            } else {
                print("Entry: Failed to fetch index in list by day: \(dailyDoDB.lastErrorMessage())")
            }
        }else{
            print("Failed to open DB")
            
        }
        print("The latest index in list for the day \(day) is 0")
        return 0
        
    }



}
