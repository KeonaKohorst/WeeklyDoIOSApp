//
//  ViewController.swift
//  ToDoApp
//
//  Created by COSC Student on 2025-03-06.

//next step i want to use DB instead of user default, and then start implementing features like this:
// - daily tasks, these repeat every day and you can mark them off every day
// - only 1 day task, when inside daily tasks, for the current day you can add a special current day task which doesn't repeat the next day
// - the ability to rearrange your tasks by dragging and dropping, order is not decided based on time, the user decides order themselves.
// - ability to add a task between any two other tasks

//app can be called DailyDo
//when you open it you can see all your tasks for the day
//when you finish one, it dissappears from the main view but you can go to another to see what you have finished today
//when you add one, you can do so by clicking between any two tasks

//buttons:
// Add Repeated Task
// Add Current Day Task
// See Completed Tasks (only for the day)

//every day it would reset the view back to all repeated daily tasks, and it would empty finished tasks.

import UIKit

class ViewController: UIViewController {
    //var tasks = [String]()
    var tasks: [String] = []
    var descriptions: [String] = []
    var ids: [Int] = []
    var weekday: String = ""
    
    var databasePath = String()
    @IBOutlet weak var plainTableView: UITableView!
    @IBOutlet weak var noneLabel: UILabel!
  
    
    @IBAction func didTapAdd(){
        let vc = storyboard?.instantiateViewController(identifier: "entry") as! EntryViewController
        
        vc.title = "New Task"
        vc.weekday = weekday
        vc.update = {
            //when we call this function we wanna reload the table view
            //and refetch the tasks
            DispatchQueue.main.async{ //make sure we prioritize updating the actual tasks
                self.updateTasks()
            }
        }
        navigationController?.pushViewController(vc, animated: true)
    }
    
    @IBAction func didTapSort(){
        if plainTableView.isEditing{
            plainTableView.isEditing = false
        }else{
            plainTableView.isEditing = true
        }
    }
  
    
    func updateTasks(){
        print("ENTERING UPDATE TASKS IN VIEW CONTROLLER")
        //get tasks from the DB
        if(weekday == "All"){
            getAllUnfinishedTasks()
        }else{
            print("Geting all unfinished tasks for weekday \(weekday)")
            getAllUnfinishedTasksForWeekday()
        }
        
        plainTableView.reloadData() //reload table view to show new updated tasks
        
        if tasks.count > 0 {
            noneLabel.text = ""
            self.plainTableView.isHidden = false
        }else{
            noneLabel.text = "Nothing to do!"
            self.plainTableView.isHidden = true
        }
    }
    
    @IBAction func getAllUnfinishedTasks(){
        tasks.removeAll() //dont want to show duplicates
        ids.removeAll()
        descriptions.removeAll()
        
        let dailyDoDB = FMDatabase(path: databasePath as String)
        
        if (dailyDoDB.open()) {
            let querySQL = "SELECT id, taskString, description FROM tasks WHERE finished != true;"
            if let results: FMResultSet = dailyDoDB.executeQuery(querySQL, withArgumentsIn: []) {
            
                while results.next() {
                    let taskID = Int(results.int(forColumn: "id"))  // Get task ID as Int
                    if let taskString = results.string(forColumn: "taskString") {
                        tasks.append(taskString)
                        ids.append(taskID)
                    }
                    
                    if let desc = results.string(forColumn: "description"){
                        descriptions.append(desc)
                    }else{
                        descriptions.append("")
                    }
                }
                print("Retrieved Tasks: \(tasks)")
                print("Retrieved IDs: \(ids)")
                print("Retrieved Descriptions: \(descriptions)")
                
                let selectSQL = "SELECT t.taskString, t.weekday, w.id, w.name FROM tasks t, weekdays w WHERE t.finished != true AND w.id = t.weekday;"
                print("Checking query results")
                if let results: FMResultSet = dailyDoDB.executeQuery(selectSQL, withArgumentsIn: []) {
                    
                    while results.next() {
                         // Get task ID as Int
                        let taskString = results.string(forColumn: "taskString")
                        let wID = Int(results.int(forColumn: "weekday"))
                        
                        let weekdayID = Int(results.int(forColumn: "id"))
                        
                        let day = results.string(forColumn: "name")
                      
                        print("Task: \(taskString!) wID: \(wID), weekday id: \(weekdayID), day: \(day!)")
                    }
                }
                
            } else {
                print("No records found.")
                
            }
            dailyDoDB.close()
            
        }
    }
    
    @IBAction func getAllUnfinishedTasksForWeekday() {
        print("GETTING UNFINISHED TASKS FOR \(weekday)")
        //

        tasks.removeAll() // Remove duplicates
        ids.removeAll()
        descriptions.removeAll()

        let dailyDoDB = FMDatabase(path: databasePath as String)

        if dailyDoDB.open() {
            let querySQL = "SELECT t.id, t.taskString, t.description, w.name FROM tasks t JOIN weekdays w ON w.id = t.weekday WHERE t.finished != true AND w.name = '\(weekday)';"
            if let results: FMResultSet = dailyDoDB.executeQuery(querySQL, withArgumentsIn: []) {
                while results.next() {
                    let taskID = Int(results.int(forColumn: "id"))  // Get task ID as Int
                    if let taskString = results.string(forColumn: "taskString") {
                        tasks.append(taskString)
                        ids.append(taskID)
                    }

                    if let desc = results.string(forColumn: "description") {
                        descriptions.append(desc)
                    } else {
                        descriptions.append("")
                    }
                }
                print("Retrieved Tasks: \(tasks)")
                print("Retrieved IDs: \(ids)")
                print("Retrieved Descriptions: \(descriptions)")
            } else {
                print("Error executing query: \(dailyDoDB.lastErrorMessage())")
            }

            
            
            
            
           

            dailyDoDB.close()
        } else {
            print("Error opening database: \(dailyDoDB.lastErrorMessage())")
        }
    }

    @IBAction func getAllFinishedTasks(){
        tasks.removeAll() //dont want to show duplicates
        ids.removeAll()
        descriptions.removeAll()
        
        let dailyDoDB = FMDatabase(path: databasePath as String)
        
        if (dailyDoDB.open()) {
            let querySQL = "SELECT id, taskString, description FROM tasks WHERE finished = true;"
            if let results: FMResultSet = dailyDoDB.executeQuery(querySQL, withArgumentsIn: []) {
                
                while results.next() {
                    let taskID = Int(results.int(forColumn: "id"))  // Get task ID as Int
                    if let taskString = results.string(forColumn: "taskString") {
                        tasks.append(taskString)
                        ids.append(taskID)
                    }
                    
                    if let desc = results.string(forColumn: "description"){
                        descriptions.append(desc)
                    }else{
                        descriptions.append("")
                    }
                }
                print("Retrieved Finished Tasks: \(tasks)")
                print("Retrieved Finished IDs: \(ids)")
                print("Retrieved Finished Descriptions: \(descriptions)")
                
            } else {
                print("No records found.")
                
            }
            
            
            dailyDoDB.close()
            
        }
    }
  
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        self.title = "\(weekday)"
        plainTableView.dataSource = self
        plainTableView.delegate = self
        
       
      
        
        //set up database
        let filemgr = FileManager.default
        let dirPaths = filemgr.urls(for: .documentDirectory, in: .userDomainMask)
        
        databasePath = dirPaths[0].appendingPathComponent("dailydo.db").path
        
        if !filemgr.fileExists(atPath: databasePath as String) { //this only runs if there is not already a db file
           let dailyDoDB = FMDatabase(path: databasePath as String)
        
        
            if (dailyDoDB.open()) {
                print("OPENED DB")
                
                let sql_stmt = """
                            CREATE TABLE IF NOT EXISTS Tasks (
                                id INTEGER PRIMARY KEY NOT NULL,
                                taskString TEXT,
                                description TEXT,
                                indexInList INTEGER,
                                weekday INTEGER,
                                finished BOOLEAN DEFAULT 0,
                                oneTimeTask BOOLEAN DEFAULT 0,
                                tag INTEGER,
                                date TEXT,
                                FOREIGN KEY (tag) REFERENCES Tags (id),
                                FOREIGN KEY (weekday) REFERENCES Weekdays (id)
                            );

                            CREATE TABLE IF NOT EXISTS Tags (
                                id INTEGER PRIMARY KEY NOT NULL,
                                tag TEXT
                            );

                            CREATE TABLE IF NOT EXISTS Weekdays (
                                id INTEGER PRIMARY KEY NOT NULL,
                                name TEXT
                            );
                            
                            

                            """
                
                    if !(dailyDoDB.executeStatements(sql_stmt)) {
                        print("Error: \(dailyDoDB.lastErrorMessage())")
                    }
                
                    //fill the weekdays and tags tables
                    populateDB()

                    dailyDoDB.close()
            
        } else {
            print("Error: \(dailyDoDB.lastErrorMessage())") }
            print("COULD NOT OPEN DB")
        }
        
       
        
        
        // retrieve the saved tasks that currently exist
        updateTasks()
        
    }
    
    @objc func populateDB(){
        let dailyDoDB = FMDatabase(path: databasePath as String)
        
        if dailyDoDB.open() {
            print("OPENED DB")

            // Insert Tags
            let tags = ["Work", "School", "Misc", "Recreational", "Time sensitive", "High priority", "Low priority"]
            for tag in tags {
                let insertTagSQL = "INSERT INTO Tags (tag) SELECT ? WHERE NOT EXISTS (SELECT 1 FROM Tags WHERE tag = ?);"
                if !dailyDoDB.executeUpdate(insertTagSQL, withArgumentsIn: [tag, tag]) {
                    print("Error inserting tag \(tag): \(dailyDoDB.lastErrorMessage())")
                }
            }

            // Insert Weekdays
            let weekdays = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]
            for day in weekdays {
                let insertDaySQL = "INSERT INTO Weekdays (name) SELECT ? WHERE NOT EXISTS (SELECT 1 FROM Weekdays WHERE name = ?);"
                if !dailyDoDB.executeUpdate(insertDaySQL, withArgumentsIn: [day, day]) {
                    print("Error inserting weekday \(day): \(dailyDoDB.lastErrorMessage())")
                }
            }

            print("Inserted weekdays and tags successfully")
            dailyDoDB.close()
        } else {
            print("Error opening database: \(dailyDoDB.lastErrorMessage())")
        }
    }

    @objc func deleteTask(taskIDDB: Int){
        print("TASK index RECEIVED IS   ", taskIDDB)

        let dailyDoDB = FMDatabase(path: databasePath as String)
        if (dailyDoDB.open()) {
        let deleteSQL = "DELETE FROM Tasks WHERE id = '\(taskIDDB)'"
        let result = dailyDoDB.executeUpdate(deleteSQL, withArgumentsIn: [])
            if !result {
                print("Error: \(dailyDoDB.lastErrorMessage())")
                
            } else {
                print("Deleted task with ID: \(taskIDDB)")
                updateTasks()
            }
            dailyDoDB.close()
        } else {
            print("Error: \(dailyDoDB.lastErrorMessage())")
        }
    }
    


}

extension ViewController: UITableViewDelegate{
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath){
        tableView.deselectRow(at: indexPath, animated: true)
        
        let vc = storyboard?.instantiateViewController(identifier: "task") as! TaskViewController
        
        print("Row selected is \(indexPath.row)")
        vc.title = "New Task"
        vc.taskName = tasks[indexPath.row]
        print("Sending task name \(tasks[indexPath.row])")
        vc.taskIndex = indexPath.row
        vc.taskID = ids[indexPath.row]
        vc.taskDescription = descriptions[indexPath.row]
        vc.update = {
            DispatchQueue.main.async{ //make sure we prioritize updating the actual tasks
                self.updateTasks()
            }
        }
        print("task ID being sent is: ", indexPath.row)
        print("task description being sent is: ", descriptions[indexPath.row])
        navigationController?.pushViewController(vc, animated: true)
        
    }
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
            let deleteAction = UIContextualAction(style: .destructive, title: "Delete") { (_, _, completionHandler) in
                
                // Remove the task from the data source
               // self.tasks.remove(at: indexPath.row)
               // self.descriptions.remove(at: indexPath.row)
                
                let idToRemove = self.ids[indexPath.row]
              //  self.ids.remove(at: indexPath.row)

                // Delete row from the table view
                //tableView.deleteRows(at: [indexPath], with: .automatic)
                
                // Delete from the database
                self.deleteTask(taskIDDB: idToRemove)

                completionHandler(true) // Mark the action as completed
            }
            
            return UISwipeActionsConfiguration(actions: [deleteAction])
    }
    
    
}

extension ViewController: UITableViewDataSource{
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int{
        return tasks.count
    }
    
    func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        tasks.swapAt(sourceIndexPath.row, destinationIndexPath.row)
        ids.swapAt(sourceIndexPath.row, destinationIndexPath.row)
        descriptions.swapAt(sourceIndexPath.row, destinationIndexPath.row)
    }
    
    //this is only called when tasks.count > 0
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        //dequeue means to reuse table view cells to improve performance
        //and memory usage
        //recycles cells which are no longer visible on the scene
        let cell = tableView.dequeueReusableCell(withIdentifier: "TaskCell", for: indexPath)
        cell.backgroundColor = UIColor(named: "pink")
        cell.textLabel?.font = UIFont.systemFont(ofSize: 18, weight: .bold)
        cell.detailTextLabel?.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        
        cell.textLabel?.text = tasks[indexPath.row]
        cell.detailTextLabel?.text = descriptions[indexPath.row]
        return cell
    }
}

