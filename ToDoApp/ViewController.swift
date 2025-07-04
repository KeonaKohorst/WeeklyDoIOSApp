//
//  ViewController.swift
//  ToDoApp
//
//  Created by COSC Student on 2025-03-06.



import UIKit

struct Task{
    let weekday: String
    let taskString: String
    let description: String
    let indexInList: Int
    let id: Int
    let tag: Int
}

class ViewController: UIViewController {
    
    var category: String = ""
    
    var groupedTasks: [String: [Task]] = [:]
    var weekdaysOrder: [String] = ["General", "Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]
    
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
    
    
    
    var databasePath = String()
    @IBOutlet weak var plainTableView: UITableView!
    @IBOutlet weak var noneLabel: UILabel!
    @IBOutlet weak var sortButton: UIBarButtonItem!
    @IBOutlet weak var deleteAllButton: UIBarButtonItem!
    
    @IBAction func didTapAdd(){
        let vc = storyboard?.instantiateViewController(identifier: "entry") as! EntryViewController
        vc.title = "New Task"
        
        //weekday is category, could be a tag name.
        if(isWeekday(day: category) || category == "All"){
            
            
            vc.weekday = category
            
        }else{
            //if finished or tag
            vc.weekday = "All"
            if(category == "Finished"){
                vc.tag = "None"
            }else{
                vc.tag = category
            }
        }
        
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
            sortButton.title = "Sort"
        }else{
            plainTableView.isEditing = true
            sortButton.title = "Stop"
        }
    }
    
    @IBAction func didTapDeleteAll(){
        print("DELETING ALL FINISHED TASKS")
        let dailyDoDB = FMDatabase(path: databasePath as String)
        
        if (dailyDoDB.open()) {
            let deleteSQL = "DELETE FROM tasks WHERE finished = true"
            if dailyDoDB.executeUpdate(deleteSQL, withArgumentsIn: []) {
                print("Successfully deleted all finished tasks")
            } else {
                print("Failed to delete all finished tasks: \(dailyDoDB.lastErrorMessage())")
            }
            
            dailyDoDB.close()
            print("EXECUTED DELETE ALL QUERY")
        }else{
            print("Failed to open DB")
            
        }
        updateTasks()
        print("DONE DELETING ALL FINISHED TASKS")
        
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
            print("View controller get id for weekday has name \(name)")
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
        //print("ENTERING UPDATE TASKS IN VIEW CONTROLLER")
        //get tasks from the DB
        if(category == "All"){
            getAllUnfinishedTasks()
            //printGroupedTasks(groupedTasks)
        }else if(category == "Finished"){
            //print("Category is finished tasks")
            getAllFinishedTasks()
            //printGroupedTasks(groupedTasks)
        }else if(tagIdMap.keys.contains(category)){
            getAllUnfinishedTasksByTag(tag: category)
            //printGroupedTasks(groupedTasks)
        }else{
            //print("Getting all unfinished tasks for weekday \(weekday)")
            getAllUnfinishedTasksForWeekday()
            //printGroupedTasks(groupedTasks)
        }
        
        
        
        plainTableView.reloadData() //reload table view to show new updated tasks
        
        //if there are no tasks show the message "Nothing to do"
        if groupedTasks.keys.count > 0 {
            noneLabel.text = ""
            self.plainTableView.isHidden = false
        }else{
            if(category != "Finished"){
                noneLabel.text = "Nothing to do!"
            }else{
                noneLabel.text = "Nothing done yet!"
            }
            self.plainTableView.isHidden = true
        }
    }
    
    func getAllUnfinishedTasksByTag(tag: String){
        groupedTasks.removeAll()
        
        let dailyDoDB = FMDatabase(path: databasePath as String)
        
        if (dailyDoDB.open()) {
            let tagID = tagIdMap[tag]
            let querySQL = "SELECT id, taskString, description, indexInList, weekday, tag FROM tasks WHERE finished != true AND tag=\(tagID!) AND date IS NULL ORDER BY weekday, indexInList;"
            if let results: FMResultSet = dailyDoDB.executeQuery(querySQL, withArgumentsIn: []) {
            
                while results.next() {
                    let taskID = Int(results.int(forColumn: "id"))  // Get task ID as Int
                    let taskString = results.string(forColumn: "taskString" ) ?? "Untitled"
                    let desc = results.string(forColumn: "description") ?? ""
                    let weekdayID = Int(results.int(forColumn: "weekday"))
                    let tagID = Int(results.int(forColumn: "tag"))
                    //print("Weekday ID from query for task \(taskString) is \(weekdayID)")
                    
                    var weekday = "General"
                    if(weekdayID != 0){
                        weekday = getWeekdayById(id: weekdayID)
                    }
                    let indexInList = Int(results.int(forColumn: "indexInList"))
                    
                    let task = Task(weekday: weekday, taskString: taskString, description: desc, indexInList: indexInList, id: taskID, tag: tagID)
                    
                    if groupedTasks[weekday] == nil {
                        groupedTasks[weekday] = []
                    }
                    groupedTasks[weekday]?.append(task)
                }
                
            } else {
                print("No records found.")
                
            }
            dailyDoDB.close()
            
        }    }
    
    @IBAction func getAllUnfinishedTasks(){
        
        groupedTasks.removeAll()
        
        let dailyDoDB = FMDatabase(path: databasePath as String)
        
        if (dailyDoDB.open()) {
            let querySQL = "SELECT id, taskString, description, indexInList, weekday, tag FROM tasks WHERE finished != true AND date IS NULL ORDER BY weekday, indexInList;"
            if let results: FMResultSet = dailyDoDB.executeQuery(querySQL, withArgumentsIn: []) {
            
                while results.next() {
                    let taskID = Int(results.int(forColumn: "id"))  // Get task ID as Int
                    let taskString = results.string(forColumn: "taskString" ) ?? "Untitled"
                    let desc = results.string(forColumn: "description") ?? ""
                    let weekdayID = Int(results.int(forColumn: "weekday"))
                    let tagID = Int(results.int(forColumn: "tag"))
                    //print("Weekday ID from query for task \(taskString) is \(weekdayID)")
                    
                    var weekday = "General"
                    if(weekdayID != 0){
                        weekday = getWeekdayById(id: weekdayID)
                    }
                    let indexInList = Int(results.int(forColumn: "indexInList"))
                    
                    let task = Task(weekday: weekday, taskString: taskString, description: desc, indexInList: indexInList, id: taskID, tag: tagID)
                    
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
        print("GETTING UNFINISHED TASKS FOR \(category)")
        
        groupedTasks.removeAll()

        let dailyDoDB = FMDatabase(path: databasePath as String)

        if dailyDoDB.open() {
            let querySQL = "SELECT t.id, t.taskString, t.description, w.name, t.indexInList, t.tag FROM tasks t JOIN weekdays w ON w.id = t.weekday WHERE t.finished != true AND w.name = '\(category)' AND date IS NULL ORDER BY t.indexInList;"
            if let results: FMResultSet = dailyDoDB.executeQuery(querySQL, withArgumentsIn: []) {
                while results.next() {
                    let taskID = Int(results.int(forColumn: "id"))  // Get task ID as Int
                    let taskString = results.string(forColumn: "taskString") ?? "Untitled"
                    let desc = results.string(forColumn: "description") ?? ""
                    let weekday = results.string(forColumn: "name") ?? "General"
                    let indexInList = Int(results.int(forColumn: "indexInList"))
                    let tagID = Int(results.int(forColumn: "tag"))
                    
                    let task = Task(weekday: weekday, taskString: taskString, description: desc, indexInList: indexInList, id: taskID, tag: tagID)
                    
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
        //print("GETTING FINISHED TASKS")
        groupedTasks.removeAll()
        
        let dailyDoDB = FMDatabase(path: databasePath as String)
        
        if (dailyDoDB.open()) {
            let querySQL = "SELECT id, taskString, description, indexInList, weekday, tag FROM tasks WHERE finished = true and DATE IS NULL ORDER BY weekday, indexInList;"
            if let results: FMResultSet = dailyDoDB.executeQuery(querySQL, withArgumentsIn: []) {
                
                while results.next() {
                    let taskID = Int(results.int(forColumn: "id"))  // Get task ID as Int
                    let taskString = results.string(forColumn: "taskString" ) ?? "Untitled"
                    let desc = results.string(forColumn: "description") ?? ""
                    let weekdayID = Int(results.int(forColumn: "weekday"))
                    let tagID = Int(results.int(forColumn: "tag"))
                    //print("Weekday ID from query for task \(taskString) is \(weekdayID)")
                    
                    
                    var weekday = "General"
                    if(weekdayID != 0){
                        weekday = getWeekdayById(id: weekdayID)
                    }
                    let indexInList = Int(results.int(forColumn: "indexInList"))
                    
                    let task = Task(weekday: weekday, taskString: taskString, description: desc, indexInList: indexInList, id: taskID, tag: tagID)
                    //print("Task in all finished tasks is \(task)")
                    
                    if groupedTasks[weekday] == nil {
                        groupedTasks[weekday] = []
                    }
                    groupedTasks[weekday]?.append(task)
                    
                }
                //print("Done while loop through results")
                
            } else {
                print("No records found.")
                
            }
            
            
            dailyDoDB.close()
            
        }
    }
  
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        self.title = "\(category)"
        plainTableView.dataSource = self
        plainTableView.delegate = self
        plainTableView.contentInset = UIEdgeInsets(top: 10, left: 0, bottom: 0, right: 0)
        
        //hide sort button if coming from a tag or finished view
        if(category == "Finished" || isTag(tag: category)){
            sortButton.isHidden = true
        }
        
        //show delete all button if coming from finished view
        if(category == "Finished"){
            deleteAllButton.isHidden = false
        }else{
            deleteAllButton.isHidden = true
        }
      
        
        //set up database
        let filemgr = FileManager.default
        let dirPaths = filemgr.urls(for: .documentDirectory, in: .userDomainMask)
        
        databasePath = dirPaths[0].appendingPathComponent("dailydo.db").path
        print("Database path: \(databasePath)")
        
        // retrieve the saved tasks that currently exist
        updateTasks()
        
    }
    
    
    

    @objc func deleteTask(taskIDDB: Int){
        //print("TASK index RECEIVED IS   ", taskIDDB)

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
    
    @objc func doneTask(taskID: Int){
        //this function sets the finished boolean to true
        let taskIDDB = taskID
        
        //print("TASK ID in DB RECEIVED IS   ", taskIDDB)
        
        let dailyDoDB = FMDatabase(path: databasePath as String)
        if (dailyDoDB.open()) {
            let updateSQL = "UPDATE Tasks SET finished = true WHERE id = '\(taskIDDB)'"
            let result = dailyDoDB.executeUpdate(updateSQL, withArgumentsIn: [])
            if !result {
                
                print("Error: \(dailyDoDB.lastErrorMessage())")
                
            } else {
                print("Done task with ID: \(taskIDDB)")
                updateTasks()
                
                
                
            }
            dailyDoDB.close()
        } else {
            print("Error: \(dailyDoDB.lastErrorMessage())")
        }
    }
    
    @objc func notDoneTask(taskID: Int){
        //this function sets the finished boolean to true
        let taskIDDB = taskID
        
        //print("TASK ID in DB RECEIVED IS   ", taskIDDB)
        
        let dailyDoDB = FMDatabase(path: databasePath as String)
        if (dailyDoDB.open()) {
            let updateSQL = "UPDATE Tasks SET finished = false WHERE id = '\(taskIDDB)'"
            let result = dailyDoDB.executeUpdate(updateSQL, withArgumentsIn: [])
            if !result {
                
                print("Error: \(dailyDoDB.lastErrorMessage())")
                
            } else {
                print("Not done task with ID: \(taskIDDB)")
                updateTasks()
                
                
                
            }
            dailyDoDB.close()
        } else {
            print("Error: \(dailyDoDB.lastErrorMessage())")
        }
    }
    
    //function to show confetti when the user swipes and marks a task as done
    func launchConfetti() {
       let confettiLayer = CAEmitterLayer()
       confettiLayer.emitterPosition = CGPoint(x: view.bounds.midX, y: -10) // Start from top
       confettiLayer.emitterShape = .line
       confettiLayer.emitterSize = CGSize(width: view.bounds.width, height: 1)
       confettiLayer.emitterCells = createConfettiCells()
       
       view.layer.addSublayer(confettiLayer)
       
       //stop after 2 seconds
       DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
           confettiLayer.birthRate = 0
       }
       
       //remove confetti after it's done animating
       DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
           confettiLayer.removeFromSuperlayer()
       }
   }
   
   private func createConfettiCells() -> [CAEmitterCell] {
       let colorNames = ["confettiPink", "confettiYellow", "green", "confettiBlue", "purple"]
       
       
       return colorNames.compactMap{ name in
           guard let color = UIColor(named: name) else { return nil }
       
      
           let cell = CAEmitterCell() //create a single particle
           cell.birthRate = 2 // decides the amount of confetti particles per second
           cell.lifetime = 1.5 //how many seconds each confetti particle is visible before disappearing
           cell.velocity = CGFloat.random(in: 90...150) // how fast the confetti moves
           cell.velocityRange = 30 //makes it so diff particles have diff speed
           cell.emissionLongitude = .pi //direction in which the confetti is emitted
           cell.emissionRange = .pi / 8 //adds variation to emission angle
           cell.spin = CGFloat.random(in: -0.5...0.5) //makes confetti spin as it falls
           cell.scale = 0.3 // size of each particle
           cell.contents = createColoredConfettiImage(color: color).cgImage //assigns an image to the particle
           return cell
       }
   }
       
    
    
    private func createColoredConfettiImage(color: UIColor) -> UIImage {
        let size = CGSize(width: 10, height: 10)
        return UIGraphicsImageRenderer(size: size).image { context in
            color.setFill()
            let path = UIBezierPath(roundedRect: CGRect(origin: .zero, size: size), cornerRadius: 2)
            path.fill()
        }
    }
    


}

extension ViewController: UITableViewDelegate{
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath){
        tableView.deselectRow(at: indexPath, animated: true)
        
        var thisWeekday = "unknown"
        var finishedTask = false
        var selectedTask: Task? = nil
        if tagIdMap.keys.contains(category){
            // User selected from the tag view
            let selectedTag = category
            let matchingTasks = groupedTasks.values.flatMap  { $0 }.filter { $0.tag == tagIdMap[selectedTag] }
            
            if indexPath.row < matchingTasks.count{
                selectedTask = matchingTasks[indexPath.row]
            }
        
        }else if(category == "Finished"){
            let day = self.weekdaysOrder[indexPath.section]
            let tasksForDay = self.groupedTasks[day] //holds all tasks for the day of the section
            
            //get the title and descrption from the selected cell
            if let cell = tableView.cellForRow(at: indexPath) {
                let taskTitle = cell.textLabel?.text ?? ""
                let taskDesc = cell.detailTextLabel?.text ?? ""
                print("Task title to delete is: \(taskTitle)")
                
                //search through groupedTasks to get the task object based on title and description
                if let foundTask = tasksForDay!.first(where: {$0.taskString == taskTitle && $0.description == taskDesc}){
                    selectedTask = foundTask
                    finishedTask = true
                }else{
                    print("Couldn't find a task with title \(taskTitle) and desc \(taskDesc)")
                }
            }else{
                print("Error getting cell")
            }
            
        }else{
            //the task is a weekday/general selection
            thisWeekday = "General"
            if(category == "All"){
                thisWeekday = weekdaysOrder[indexPath.section]
            }else if(!tagIdMap.keys.contains(category)){
                thisWeekday = category
            }
            selectedTask = groupedTasks[thisWeekday]?[indexPath.row]
            
        }
        
        
        guard let task = selectedTask else{
            print("No task found for selection at row \(indexPath.row)")
            return
        }
        
        
       // guard let task = groupedTasks[thisWeekday]?[indexPath.row] else {return}
      
        
        let vc = storyboard?.instantiateViewController(identifier: "task") as! TaskViewController
        
        print("Row selected is \(indexPath.row)")
        vc.title = "New Task"

        vc.taskName = task.taskString
        print("Sending task name \(task.taskString)")
        vc.taskID = task.id
        vc.taskDescription = task.description
        vc.taskIndex = indexPath.row
        vc.weekday = task.weekday
        print("Passing weekday to ask controller \(task.weekday)")
        vc.tagID = task.tag
        vc.taskFinished = finishedTask
        vc.weekdayID = getIdForWeekday(name: category)
        vc.update = {
            DispatchQueue.main.async{ //make sure we prioritize updating the actual tasks
                self.updateTasks()
            }
        }
        //print("task ID for the array being sent is: ", indexPath.row)
        //print("task description being sent is: ", task.description)
        navigationController?.pushViewController(vc, animated: true)
        
    }
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
            let deleteAction = UIContextualAction(style: .destructive, title: "Delete") { (_, _, completionHandler) in
 
                
                if(self.category == "All" || self.isWeekday(day: self.category)){
                    let day = (self.category == "All") ? self.weekdaysOrder[indexPath.section] : self.category
                    
                    //get the task for the weekday or for all and delete
                    if let tasks = self.groupedTasks[day]{
                        let task = tasks[indexPath.row]
                        let id = task.id
                        //let idToRemove = self.ids[indexPath.row]

                        // Delete from the database
                        self.deleteTask(taskIDDB: id)

                        completionHandler(true) // Mark the action as completed
                        
                    }
                    
                }else{
                    //if the category is the finished filter or a tag filter we need to look for the specific task bc row index will not be reliable
                    let day = self.weekdaysOrder[indexPath.section]
                    let tasksForDay = self.groupedTasks[day] //holds all tasks for the day of the section
                    
                    //get the title and descrption from the selected cell
                    if let cell = tableView.cellForRow(at: indexPath) {
                        let taskTitle = cell.textLabel?.text ?? ""
                        let taskDesc = cell.detailTextLabel?.text ?? ""
                        print("Task title to delete is: \(taskTitle)")
                        
                        //search through groupedTasks to get the task object based on title and description
                        if let foundTask = tasksForDay!.first(where: {$0.taskString == taskTitle && $0.description == taskDesc}){
                            //delete the match that was found
                            let id = foundTask.id
                            self.deleteTask(taskIDDB: id)
                            completionHandler(true) // Mark the action as completed
                        }else{
                            print("Couldn't find a task with title \(taskTitle) and desc \(taskDesc)")
                        }
                    }else{
                        print("Error getting cell")
                    }
                }

            }
        
        let markDoneAction = UIContextualAction(style: .normal, title: "Done"){ action, view, completionHandler in
            print("Done tapped")
            
            if(self.category == "All" || self.isWeekday(day: self.category)){
                let day = (self.category == "All") ? self.weekdaysOrder[indexPath.section] : self.category
                
                //get the task for the weekday or for all and delete
                if let tasks = self.groupedTasks[day]{
                    let task = tasks[indexPath.row]
                    let id = task.id
                    //let idToRemove = self.ids[indexPath.row]

                    // Delete from the database
                    self.doneTask(taskID: id)

                    completionHandler(true) // Mark the action as completed
                    self.launchConfetti()
                    
                }
                
            }else{
                //if the category is the finished filter or a tag filter we need to look for the specific task bc row index will not be reliable
                let day = self.weekdaysOrder[indexPath.section]
                let tasksForDay = self.groupedTasks[day] //holds all tasks for the day of the section
                
                //get the title and descrption from the selected cell
                if let cell = tableView.cellForRow(at: indexPath) {
                    let taskTitle = cell.textLabel?.text ?? ""
                    let taskDesc = cell.detailTextLabel?.text ?? ""
                    print("Task title tom mark done is: \(taskTitle)")
                    
                    //search through groupedTasks to get the task object based on title and description
                    if let foundTask = tasksForDay!.first(where: {$0.taskString == taskTitle && $0.description == taskDesc}){
                        //delete the match that was found
                        let id = foundTask.id
                        self.doneTask(taskID: id)
                        completionHandler(true) // Mark the action as completed
                        self.launchConfetti()
                    }else{
                        print("Couldn't find a task with title \(taskTitle) and desc \(taskDesc)")
                    }
                }else{
                    print("Error getting cell")
                }
            }
            
        }
        markDoneAction.backgroundColor = UIColor(named: "mint" )
        
        let putBackAction = UIContextualAction(style: .normal, title: "Put Back"){ action, view, completionHandler in
            let day = self.weekdaysOrder[indexPath.section]
            let tasksForDay = self.groupedTasks[day] //holds all tasks for the day of the section
            
            //get the title and descrption from the selected cell
            if let cell = tableView.cellForRow(at: indexPath) {
                let taskTitle = cell.textLabel?.text ?? ""
                let taskDesc = cell.detailTextLabel?.text ?? ""
                print("Task title tom mark not done is: \(taskTitle)")
                
                //search through groupedTasks to get the task object based on title and description
                if let foundTask = tasksForDay!.first(where: {$0.taskString == taskTitle && $0.description == taskDesc}){
                    //delete the match that was found
                    let id = foundTask.id
                    self.notDoneTask(taskID: id)
                    completionHandler(true) // Mark the action as completed
                }else{
                    print("Couldn't find a task with title \(taskTitle) and desc \(taskDesc)")
                }
                
            }
        }
        putBackAction.backgroundColor = UIColor(named: "blue")
            
        if(category != "Finished"){
            return UISwipeActionsConfiguration(actions: [deleteAction, markDoneAction])
        }else{
            return UISwipeActionsConfiguration(actions: [deleteAction, putBackAction])
        }
    }
    
    func isTag(tag: String) -> Bool {
        return tagIdMap.keys.contains(tag)
        
    }
    
    func isWeekday(day: String) -> Bool {
        return weekdaysOrder.contains(day)
    }
    
}

extension ViewController: UITableViewDataSource{
    
    func numberOfSections(in tableView: UITableView) -> Int {
        
        //return groupedTasks.keys.count
        if(category == "All" || category == "Finished" || tagIdMap.keys.contains(category)){
            //print("Number of sections in table view is 8")
            return 8
        }else{
            //print("Number of sections in table view is 1")
            return 1
        }
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if(category == "All" || category == "Finished" || tagIdMap.keys.contains(category)){
            return weekdaysOrder[section]
        }else{
            return category
        }
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if(category == "All" || category == "Finished" || tagIdMap.keys.contains(category)){
           return 30
        }else{
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if(category != "All" && category != "Finished" && !tagIdMap.keys.contains(category)){
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
            titleLabel.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 16),
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
        if category == "All" || category == "Finished" || tagIdMap.keys.contains(category) {
            //let keys = Array(groupedTasks.keys).sorted { weekdaysOrder.firstIndex(of: $0) ?? Int.max < weekdaysOrder.firstIndex(of: $1) ?? Int.max }
            //return groupedTasks[keys[section]]?.count ?? 0
            let weekday = weekdaysOrder[section]
            return groupedTasks[weekday]?.count ?? 0
            
        } else {
            return groupedTasks[category]?.count ?? 0
        }
        
    }
    
    func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        
        //print("Source index section is \(sourceIndexPath.section)")
        //let day = groupedTasks.keys.sorted()[sourceIndexPath.section]
        let day = (self.category == "All" || category == "Finished" || tagIdMap.keys.contains(category)) ? self.weekdaysOrder[sourceIndexPath.section] : self.category
        //let destDay = (self.weekday == "All" || weekday == "Finished" || tagIdMap.keys.contains(weekday)) ? self.weekdaysOrder[destinationIndexPath.section] : self.weekday
        
        //let dayID = getIdForWeekday(name: day)
        //let destDayID = getIdForWeekday(name: destDay)
        
        if var tasks = groupedTasks[day]{
            let sourceTask = tasks[sourceIndexPath.row]
            //print("Source task is \(sourceTask) at row \(sourceIndexPath.row) and day \(day)")
          
            
            let destinationTask = tasks[destinationIndexPath.row]
            //print("Destination task is \(destinationTask) at row \(destinationIndexPath.row) and day \(destDay)")
            
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

        if (category == "All" || category == "Finished" || tagIdMap.keys.contains(category)){
            let thisWeekday = weekdaysOrder[indexPath.section]
            task = groupedTasks[thisWeekday]?[indexPath.row]
        } else {
            task = groupedTasks[category]?[indexPath.row]
        }

        if let task = task {
            cell.textLabel?.text = task.taskString
            cell.detailTextLabel?.text = task.description
            
            let tag = idTagMap[task.tag]
            if(tag == "School"){
                cell.imageView?.image = UIImage(systemName: "book.fill")
                cell.imageView?.tintColor = UIColor(named: "white")
                
            }else if(tag == "None"){
                cell.imageView?.image = UIImage(systemName: "globe")
                cell.imageView?.tintColor = UIColor(named: "white")
                
            }else if(tag == "Work"){

                cell.imageView?.image = UIImage(systemName: "briefcase.fill")
                cell.imageView?.tintColor = UIColor(named: "white")
                    
            }else if(tag == "Fun"){
                cell.imageView?.image = UIImage(systemName: "smiley.fill")
                cell.imageView?.tintColor = UIColor(named: "white")
            }else if(tag == "Event"){
                cell.imageView?.image = UIImage(systemName: "burst.fill")
                cell.imageView?.tintColor = UIColor(named: "white")
            }else if(tag == "Chore"){
                cell.imageView?.image = UIImage(systemName: "house.fill")
                cell.imageView?.tintColor = UIColor(named: "white")
            }
        } else {
            cell.textLabel?.text = "No Task"
            cell.detailTextLabel?.text = ""
        }

        return cell

        
    }
    
    
}

