//
//  DateEntryViewController.swift
//  ToDoApp
//
//  Created by COSC Student on 2025-03-31.
//

import UIKit

class DateEntryViewController: UIViewController, UITextFieldDelegate {
    
    @IBOutlet var field: UITextField!
    @IBOutlet var descField: UITextView!
    @IBOutlet var datePicker: UIDatePicker!
   
    var databasePath = String()
    var update: (() -> Void)?
    
    var chosenDate = Date()
    

 
  

    override func viewDidLoad() {
        super.viewDidLoad()
        
        //configure style of text view
        descField.layer.borderColor = UIColor(named: "pink")!.cgColor
        descField.layer.borderWidth = 1.0
        descField.layer.cornerRadius = 5.0
        descField.layer.masksToBounds = true
        
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
    
    @IBAction func datePickerChanged(_ sender: UIDatePicker){
        chosenDate = sender.date
    }
    
    @IBAction func textFieldDoneEditing(sender: UITextField){
        
        sender.resignFirstResponder()
    }
    
    @IBAction func onTapGestureRecognized1(_ sender: AnyObject){
        field.resignFirstResponder()
        descField.resignFirstResponder()
    }
    
    
    @objc func saveTask(){
        //save contents of the field
        guard let text = field.text, !text.isEmpty else {
            return
        }
        print("SAVING TASK ", text)
        //save task cuz not empty
        if let task = field.text, !task.isEmpty {
            
            let desc = descField.text ?? ""
            
            
            //get date string
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd HH:mm"
            let formattedDate = dateFormatter.string(from: chosenDate)
            
            
            let dailyDoDB = FMDatabase(path: databasePath as String)
            if (dailyDoDB.open()){

                // Get the ID for the day
                let insertSQL = "INSERT INTO tasks (taskString, description, date) VALUES ('\(task)', '\(desc)', '\(formattedDate)');"
                
                let result = dailyDoDB.executeUpdate(insertSQL, withArgumentsIn: [])
                
                if !result {
                    //status.text = "Failed to add task"
                    print("Error:\(dailyDoDB.lastErrorMessage())")
                } else {
                    // Get the last inserted row ID
                    let lastInsertedID = Int(dailyDoDB.lastInsertRowId)

                    print("Task Added: \(task) with ID: \(lastInsertedID) and description \(desc) and date \(formattedDate)")

             
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
    

  

}
