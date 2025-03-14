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

struct Task{
    let weekday: String
    let taskString: String
    let description: String
    let indexInList: Int
    let id: Int
}

class ViewController: UIViewController {
    //var tasks = [String]()
    //var taskss: [Task] = []
    //var tasks: [String] = []
    //var descriptions: [String] = []
    //var ids: [Int] = []
    
    var weekday: String = ""
    
    var groupedTasks: [String: [Task]] = [:]
    var weekdaysOrder: [String] = ["General", "Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]
    
    let idWeekdayMap: [Int: String] = [ //dont use this
        1: "Monday",
        2: "Sunday",
        3: "Tuesday",
        4: "Wednesday",
        5: "Thursday",
        6: "Friday",
        7: "Saturday"
    ]
    
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
    
    func getWeekdayById(id: Int) -> String {
        // Get weekday from the ID
        //print("Get weekday by id: \(id)")
        let dailyDoDB = FMDatabase(path: databasePath as String)
        
        if (dailyDoDB.open()) {
            let getSQL = "SELECT name FROM Weekdays WHERE id = '\(id)'"
            if let result = dailyDoDB.executeQuery(getSQL, withArgumentsIn: []) {
                if result.next() { // move to the first row with .next()
                    let weekday = result.string(forColumn: "name")
                    if(weekday != nil){
                        return weekday!
                    }else{
                        return "General"
                    }
                } else {
                    print("Get weekday by id function: No matching weekday found for id \(id)")
                }
            } else {
                print("Failed to fetch weekday name by id: \(dailyDoDB.lastErrorMessage())")
            }
        }else{
            print("Failed to open DB")
            
        }
        return "All"
        
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
    
    func printGroupedTasks(_ groupedTasks: [String: [Task]]) {
        for (day, tasks) in groupedTasks {
            print("Day: \(day)")
            var row = 0
            for task in tasks {
                print("  - Row \(row): \(task)")
                row += 1
            }
        }
    }

    
    
    func updateTasks(){
        print("ENTERING UPDATE TASKS IN VIEW CONTROLLER")
        //get tasks from the DB
        if(weekday == "All"){
            getAllUnfinishedTasks()
            printGroupedTasks(groupedTasks)
        }else if(weekday == "Finished"){
            print("Category is finished tasks")
            getAllFinishedTasks()
            printGroupedTasks(groupedTasks)
        }else{
            print("Getting all unfinished tasks for weekday \(weekday)")
            getAllUnfinishedTasksForWeekday()
            printGroupedTasks(groupedTasks)
        }
        
        
        
        plainTableView.reloadData() //reload table view to show new updated tasks
        
        //if there are no tasks show the message "Nothing to do"
        if groupedTasks.keys.count > 0 {
            noneLabel.text = ""
            self.plainTableView.isHidden = false
        }else{
            noneLabel.text = "Nothing to do!"
            self.plainTableView.isHidden = true
        }
    }
    
    @IBAction func getAllUnfinishedTasks(){
        
        groupedTasks.removeAll()
        
        let dailyDoDB = FMDatabase(path: databasePath as String)
        
        if (dailyDoDB.open()) {
            let querySQL = "SELECT id, taskString, description, indexInList, weekday FROM tasks WHERE finished != true ORDER BY weekday, indexInList;"
            if let results: FMResultSet = dailyDoDB.executeQuery(querySQL, withArgumentsIn: []) {
            
                while results.next() {
                    let taskID = Int(results.int(forColumn: "id"))  // Get task ID as Int
                    let taskString = results.string(forColumn: "taskString" ) ?? "Untitled"
                    let desc = results.string(forColumn: "description") ?? ""
                    let weekdayID = Int(results.int(forColumn: "weekday"))
                    //print("Weekday ID from query for task \(taskString) is \(weekdayID)")
                    
                    var weekday = "General"
                    if(weekdayID != 0){
                        weekday = getWeekdayById(id: weekdayID)
                    }
                    let indexInList = Int(results.int(forColumn: "indexInList"))
                    
                    let task = Task(weekday: weekday, taskString: taskString, description: desc, indexInList: indexInList, id: taskID)
                    
                    if groupedTasks[weekday] == nil {
                        groupedTasks[weekday] = []
                    }
                    groupedTasks[weekday]?.append(task)
                }
                
            } else {
                print("No records found.")
                
            }
            dailyDoDB.close()
            
        }
    }
    
    @IBAction func getAllUnfinishedTasksForWeekday() {
        print("GETTING UNFINISHED TASKS FOR \(weekday)")
        
        groupedTasks.removeAll()

        let dailyDoDB = FMDatabase(path: databasePath as String)

        if dailyDoDB.open() {
            let querySQL = "SELECT t.id, t.taskString, t.description, w.name, t.indexInList FROM tasks t JOIN weekdays w ON w.id = t.weekday WHERE t.finished != true AND w.name = '\(weekday)' ORDER BY t.indexInList;"
            if let results: FMResultSet = dailyDoDB.executeQuery(querySQL, withArgumentsIn: []) {
                while results.next() {
                    let taskID = Int(results.int(forColumn: "id"))  // Get task ID as Int
                    let taskString = results.string(forColumn: "taskString") ?? "Untitled"
                    let desc = results.string(forColumn: "description") ?? ""
                    let weekday = results.string(forColumn: "name") ?? "General"
                    let indexInList = Int(results.int(forColumn: "indexInList"))
                    
                    let task = Task(weekday: weekday, taskString: taskString, description: desc, indexInList: indexInList, id: taskID)
                    
                    if groupedTasks[weekday] == nil {
                        groupedTasks[weekday] = []
                    }
                    groupedTasks[weekday]?.append(task)
                    
                }
            } else {
                print("Error executing query: \(dailyDoDB.lastErrorMessage())")
            }

            dailyDoDB.close()
        } else {
            print("Error opening database: \(dailyDoDB.lastErrorMessage())")
        }
    }

    @IBAction func getAllFinishedTasks(){
        print("GETTING FINISHED TASKS")
        groupedTasks.removeAll()
        
        let dailyDoDB = FMDatabase(path: databasePath as String)
        
        if (dailyDoDB.open()) {
            let querySQL = "SELECT id, taskString, description, indexInList, weekday FROM tasks WHERE finished = true ORDER BY weekday, indexInList;"
            if let results: FMResultSet = dailyDoDB.executeQuery(querySQL, withArgumentsIn: []) {
                
                while results.next() {
                    let taskID = Int(results.int(forColumn: "id"))  // Get task ID as Int
                    let taskString = results.string(forColumn: "taskString" ) ?? "Untitled"
                    let desc = results.string(forColumn: "description") ?? ""
                    let weekdayID = Int(results.int(forColumn: "weekday"))
                    //print("Weekday ID from query for task \(taskString) is \(weekdayID)")
                    
                    
                    var weekday = "General"
                    if(weekdayID != 0){
                        weekday = getWeekdayById(id: weekdayID)
                    }
                    let indexInList = Int(results.int(forColumn: "indexInList"))
                    
                    let task = Task(weekday: weekday, taskString: taskString, description: desc, indexInList: indexInList, id: taskID)
                    print("Task in all finished tasks is \(task)")
                    
                    if groupedTasks[weekday] == nil {
                        groupedTasks[weekday] = []
                    }
                    groupedTasks[weekday]?.append(task)
                    
                }
                print("Done while loop through results")
                
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
        plainTableView.contentInset = UIEdgeInsets(top: 10, left: 0, bottom: 0, right: 0)
        
       
      
        
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
        
        var thisWeekday = "General"
        if(weekday == "All"){
            thisWeekday = weekdaysOrder[indexPath.section]
        }else{
            thisWeekday = weekday
        }
        guard let task = groupedTasks[thisWeekday]?[indexPath.row] else {return}
        
        let vc = storyboard?.instantiateViewController(identifier: "task") as! TaskViewController
        
        print("Row selected is \(indexPath.row)")
        vc.title = "New Task"

        vc.taskName = task.taskString
        print("Sending task name \(task.taskString)")
        vc.taskID = task.id
        vc.taskDescription = task.description
        vc.taskIndex = indexPath.row
        vc.weekday = thisWeekday
        vc.weekdayID = getIdForWeekday(name: weekday)
        vc.update = {
            DispatchQueue.main.async{ //make sure we prioritize updating the actual tasks
                self.updateTasks()
            }
        }
        print("task ID for the array being sent is: ", indexPath.row)
        print("task description being sent is: ", task.description)
        navigationController?.pushViewController(vc, animated: true)
        
    }
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
            let deleteAction = UIContextualAction(style: .destructive, title: "Delete") { (_, _, completionHandler) in
 
                let day = (self.weekday == "All") ? self.weekdaysOrder[indexPath.section] : self.weekday
                if let tasks = self.groupedTasks[day]{
                    let task = tasks[indexPath.row]
                    let id = task.id
                    //let idToRemove = self.ids[indexPath.row]

                    // Delete from the database
                    self.deleteTask(taskIDDB: id)

                    completionHandler(true) // Mark the action as completed
                    
                }
                
            }
            
            return UISwipeActionsConfiguration(actions: [deleteAction])
    }
    
    
}

extension ViewController: UITableViewDataSource{
    
    func numberOfSections(in tableView: UITableView) -> Int {
        
        //return groupedTasks.keys.count
        if(weekday == "All" || weekday == "Finished"){
            print("Number of sections in table view is 8")
            return 8
        }else{
            print("Number of sections in table view is 1")
            return 1
        }
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if(weekday == "All" || weekday == "Finished"){
            return weekdaysOrder[section]
        }else{
            return weekday
        }
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if(weekday == "All" || weekday == "Finished"){
           return 30
        }else{
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if(weekday != "All" && weekday != "Finished"){
            return UIView()
        }
        let headerView = UIView()
        headerView.backgroundColor = UIColor(named: "white")
        let titleLabel = UILabel()
        titleLabel.text = self.tableView(tableView, titleForHeaderInSection: section)
        titleLabel.font = UIFont.boldSystemFont(ofSize: 18)
        titleLabel.textColor = UIColor(named: "blue")
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        headerView.addSubview(titleLabel)
        
        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 16), // Adjust left padding
            titleLabel.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: -16),
            titleLabel.topAnchor.constraint(equalTo: headerView.topAnchor, constant: 4),
            titleLabel.bottomAnchor.constraint(equalTo: headerView.bottomAnchor, constant: -4)
        ])
        
        return headerView
        
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int{
        //return tasks.count
        //let weekday = weekdaysOrder[section]
       // return groupedTasks[weekday]?.count ?? 0
        if weekday == "All" || weekday == "Finished" {
            //let keys = Array(groupedTasks.keys).sorted { weekdaysOrder.firstIndex(of: $0) ?? Int.max < weekdaysOrder.firstIndex(of: $1) ?? Int.max }
            //return groupedTasks[keys[section]]?.count ?? 0
            let weekday = weekdaysOrder[section]
            return groupedTasks[weekday]?.count ?? 0
            
        } else {
            return groupedTasks[weekday]?.count ?? 0
        }
        
    }
    
    func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        
        print("Source index section is \(sourceIndexPath.section)")
        //let day = groupedTasks.keys.sorted()[sourceIndexPath.section]
        let day = (self.weekday == "All" || weekday == "Finished") ? self.weekdaysOrder[sourceIndexPath.section] : self.weekday
        let destDay = (self.weekday == "All" || weekday == "Finished") ? self.weekdaysOrder[destinationIndexPath.section] : self.weekday
        
        //let dayID = getIdForWeekday(name: day)
        //let destDayID = getIdForWeekday(name: destDay)
        
        if var tasks = groupedTasks[day]{
            let sourceTask = tasks[sourceIndexPath.row]
            print("Source task is \(sourceTask) at row \(sourceIndexPath.row) and day \(day)")
          
            
            let destinationTask = tasks[destinationIndexPath.row]
            print("Destination task is \(destinationTask) at row \(destinationIndexPath.row) and day \(destDay)")
            
            //make changes in the db
            let dailyDoDB = FMDatabase(path: databasePath as String)
            
            if (dailyDoDB.open()) {
                let updateSQL1 = "UPDATE tasks SET indexInList = \(destinationIndexPath.row) WHERE id = \(sourceTask.id);"
                let updateSQL2 = "UPDATE tasks SET indexInList = \(sourceIndexPath.row) WHERE id = \(destinationTask.id);"
                
                if let results: FMResultSet = dailyDoDB.executeQuery(updateSQL1, withArgumentsIn: []) {
                    
                    while results.next() {
                        let indexInList = Int(results.int(forColumn: "indexInList"))
                        if let taskString = results.string(forColumn: "taskString") {
                            print("task 1 \(taskString) updated to index in list: \(indexInList)")
                        }
                        
                       
                    }
                    print("Updated Task 1 Index in List")
                    
                } else {
                    print("Update of index in list failed")
                }
                
                if let results: FMResultSet = dailyDoDB.executeQuery(updateSQL2, withArgumentsIn: []) {
                    
                    while results.next() {
                        let indexInList = Int(results.int(forColumn: "indexInList"))
                        if let taskString = results.string(forColumn: "taskString") {
                            print("task 2 \(taskString) updated to index in list: \(indexInList)")
                        }
                                        }
                    print("Updated Task 2 Index in List")
                    
                } else {
                    print("Update of index in list failed")
                    
                }
                
                dailyDoDB.close()
                
            }
            
            tasks.swapAt(sourceIndexPath.row, destinationIndexPath.row)
            groupedTasks[day] = tasks
            
        }

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

        
        var task: Task?

        if weekday == "All" || weekday == "Finished" {
            let thisWeekday = weekdaysOrder[indexPath.section]
            task = groupedTasks[thisWeekday]?[indexPath.row]
        } else {
            task = groupedTasks[weekday]?[indexPath.row]
        }

        if let task = task {
            cell.textLabel?.text = task.taskString
            cell.detailTextLabel?.text = task.description
        } else {
            cell.textLabel?.text = "No Task"
            cell.detailTextLabel?.text = ""
        }

        return cell

        
    }
}

