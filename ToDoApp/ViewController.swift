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
    var ids: [Int] = []
    
    var databasePath = String()
    @IBOutlet weak var tableView: UITableView!
    
    @IBAction func didTapAdd(){
        let vc = storyboard?.instantiateViewController(identifier: "entry") as! EntryViewController
        
        vc.title = "New Task"
        vc.update = {
            //when we call this function we wanna reload the table view
            //and refetch the tasks
            DispatchQueue.main.async{ //make sure we prioritize updating the actual tasks
                self.updateTasks()
            }
        }
        navigationController?.pushViewController(vc, animated: true)
    }
    
  
    
    func updateTasks(){
        print("ENTERING UPDATE TASKS IN VIEW CONTROLLER")
        //get tasks from the DB
        getAllTasks()
        
        tableView.reloadData() //reload table view to show new updated tasks
        
    }
    
    @IBAction func getAllTasks(){
        tasks.removeAll() //dont want to show duplicates
        ids.removeAll()
        
        let dailyDoDB = FMDatabase(path: databasePath as String)
        
        if (dailyDoDB.open()) {
            let querySQL = "SELECT id, taskString FROM tasks;"
            if let results: FMResultSet = dailyDoDB.executeQuery(querySQL, withArgumentsIn: []) {
            
                while results.next() {
                    let taskID = Int(results.int(forColumn: "id"))  // Get task ID as Int
                    if let taskString = results.string(forColumn: "taskString") {
                        tasks.append(taskString)
                        ids.append(taskID)
                    }
                }
                print("Retrieved Tasks: \(tasks)")
                print("Retrieved IDs: \(ids)")
                    
            } else {
                print("No records found.")
            }
            dailyDoDB.close()
            
        }
    
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        self.title = "Tasks"
        tableView.dataSource = self
        tableView.delegate = self
        
        //set up database
        let filemgr = FileManager.default
        let dirPaths = filemgr.urls(for: .documentDirectory, in: .userDomainMask)
        
        databasePath = dirPaths[0].appendingPathComponent("dailydo.db").path
        
        if !filemgr.fileExists(atPath: databasePath as String) {
           let dailyDoDB = FMDatabase(path: databasePath as String)
        
        
        if (dailyDoDB.open()) {
      
            
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
            
        if !(dailyDoDB.executeStatements(sql_stmt)) { print("Error: \(dailyDoDB.lastErrorMessage())")
        }
        dailyDoDB.close() } else {
        print("Error: \(dailyDoDB.lastErrorMessage())") }
        }
        
        // retrieve the saved tasks that currently exist
        updateTasks()
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
        vc.update = {
            DispatchQueue.main.async{ //make sure we prioritize updating the actual tasks
                self.updateTasks()
            }
        }
        print("task ID being sent is: ", indexPath.row)
        navigationController?.pushViewController(vc, animated: true)
        
    }
    
}

extension ViewController: UITableViewDataSource{
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int{
        return tasks.count
    }
    
    //this is only called when tasks.count > 0
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        //dequeue means to reuse table view cells to improve performance
        //and memory usage
        //recycles cells which are no longer visible on the scene
        let cell = tableView.dequeueReusableCell(withIdentifier: "TaskCell", for: indexPath)
        
        cell.textLabel?.text = tasks[indexPath.row]
        return cell
    }
}

