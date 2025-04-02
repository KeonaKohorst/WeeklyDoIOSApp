//
//  CalendarViewController.swift
//  ToDoApp
//
//  Created by COSC Student on 2025-03-31.
//

import UIKit

struct DateTask{
    let taskString: String
    let description: String
    let id: Int
    let date: String
}

class CalendarViewController: UIViewController {
    
    var groupedTasks: [String: [DateTask]] = [:]
    let months: [String] = ["January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"]
    var databasePath = String()
    
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var noneLabel: UILabel!

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        tableView.dataSource = self
        tableView.delegate = self
        tableView.contentInset = UIEdgeInsets(top: 10, left: 0, bottom: 0, right: 0)
        
        let filemgr = FileManager.default
        let dirPaths = filemgr.urls(for: .documentDirectory, in: .userDomainMask)
        
        databasePath = dirPaths[0].appendingPathComponent("dailydo.db").path
        
        updateTasks()
    }
    
    override func viewDidAppear(_ animated: Bool){
        super.viewDidAppear(animated)
        
        let currentMonth = Calendar.current.component(.month, from: Date()) //1-12
        let sectionIndex = currentMonth-1
        
        let numberOfSections = tableView.numberOfSections
        let numberOfRows = tableView.numberOfRows(inSection: sectionIndex)
        
        
        if sectionIndex < numberOfSections, numberOfRows > 0 {
            
            let indexPath = IndexPath(row: 0, section: sectionIndex)
            tableView.scrollToRow(at: indexPath, at: .top, animated: true)
        }else{
            //do not scroll bc nothing in section
        }
    }
    
    @IBAction func didTapAdd(){
        print("Tapped add in calendar view")
        let vc = storyboard?.instantiateViewController(identifier: "dateEntry") as! DateEntryViewController
        vc.title = "New Dated Task"
        
        
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
        //print("ENTERING UPDATE TASKS IN CALENDAR VIEW CONTROLLER")
        //get tasks from the DB
        getAllDatedTasks()
        
        
        tableView.reloadData() //reload table view to show new updated tasks
        
        //if there are no tasks show the message "Nothing to do"
        if groupedTasks.keys.count > 0 {
            noneLabel.text = ""
            self.tableView.isHidden = false
        }else{
            noneLabel.text = "Nothing to do!"
            self.tableView.isHidden = true
        }
    }
    
    func getAllDatedTasks(){
        print("GETTING ALL DATED TASKS")
        groupedTasks.removeAll()
        
        let dailyDoDB = FMDatabase(path: databasePath as String)
        
        if (dailyDoDB.open()) {
            let querySQL = "SELECT id, taskString, description, date FROM tasks WHERE finished != true AND date IS NOT NULL ORDER BY date;"
            if let results: FMResultSet = dailyDoDB.executeQuery(querySQL, withArgumentsIn: []) {
            
                while results.next() {
                    let taskID = Int(results.int(forColumn: "id"))  // Get task ID as Int
                    let taskString = results.string(forColumn: "taskString" ) ?? "Untitled"
                    let desc = results.string(forColumn: "description") ?? ""
                    let dateString = results.string(forColumn: "date") ?? ""
                    
                    print("dateString is \(dateString)")
                    
                    let dateFormatter = DateFormatter()
                    dateFormatter.dateFormat = "yyyy-MM-dd HH:mm"
                    
                    let task = DateTask(taskString: taskString, description: desc, id: taskID, date: dateString)
                    
                    if let date = dateFormatter.date(from: dateString){
                        
                        let dateFormatter2 = DateFormatter()
                        dateFormatter.dateFormat = "MMMM"
                        
                        let monthString = dateFormatter.string(from: date)
                        
                        if groupedTasks[monthString] == nil{
                            groupedTasks[monthString] = []
                        }
                        groupedTasks[monthString]?.append(task)
                    }else{
                        print("Invalid date format")
                    }
                    
                   
                }
                print("After update tasks grouped tasks is \(groupedTasks)")
                
            } else {
                print("No records found.")
                
            }
            dailyDoDB.close()
            
        }
        
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

extension CalendarViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath){
        tableView.deselectRow(at: indexPath, animated: true)
        
        let month = months[indexPath.section]
        guard let task = groupedTasks[month]?[indexPath.row] else {return}

        let vc = storyboard?.instantiateViewController(identifier: "dateTask") as! DateTaskViewController
        
        print("Row selected is \(indexPath.row)")
        vc.title = "View Task"

        vc.taskName = task.taskString
        print("Sending task name \(task.taskString)")
        vc.taskID = task.id
        vc.taskDescription = task.description
        vc.taskDate = task.date
        //vc.taskFinished = finishedTask
       
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

                let month = self.months[indexPath.section]
                    
                //get the task for the weekday or for all and delete
                if let tasks = self.groupedTasks[month]{
                    let task = tasks[indexPath.row]
                    let id = task.id
                    //let idToRemove = self.ids[indexPath.row]

                    // Delete from the database
                    self.deleteTask(taskIDDB: id)

                    completionHandler(true) // Mark the action as completed
                    
                }
            }
        
        let markDoneAction = UIContextualAction(style: .normal, title: "Done"){ action, view, completionHandler in
            print("Done tapped")
            
         
            let month = self.months[indexPath.section]
                
                //get the task for the weekday or for all and delete
                if let tasks = self.groupedTasks[month]{
                    let task = tasks[indexPath.row]
                    let id = task.id
                    //let idToRemove = self.ids[indexPath.row]

                    // Delete from the database
                    self.deleteTask(taskIDDB: id)

                    completionHandler(true) // Mark the action as completed
        
                    self.launchConfetti()
                    
                }

        }
        markDoneAction.backgroundColor = UIColor(named: "mint" )
        
        return UISwipeActionsConfiguration(actions: [deleteAction, markDoneAction])
      
    }
}

extension CalendarViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        
        return 12;
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return months[section]
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 30
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        
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
        let month = months[section]
        
        return groupedTasks[month]?.count ?? 0
    }
    
    //this is only called when tasks.count > 0
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        print("Cell for row at has tasks: \(groupedTasks)")
        
        //dequeue means to reuse table view cells to improve performance
        //and memory usage
        //recycles cells which are no longer visible on the scene
        let cell = tableView.dequeueReusableCell(withIdentifier: "TaskCell", for: indexPath)
        cell.backgroundColor = UIColor(named: "pink")
        cell.textLabel?.font = UIFont.systemFont(ofSize: 18, weight: .bold)
        cell.detailTextLabel?.font = UIFont.systemFont(ofSize: 14, weight: .regular)

      
        let month = months[indexPath.section]
        var dayOfMonth = ""
        var hourMinute = ""
        
        var task: DateTask?
        task = groupedTasks[month]![indexPath.row]
        
        var inPast = false
        if let dateStr = task?.date {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd HH:mm"

            if let date = dateFormatter.date(from: dateStr) {
                let dfDayOfMonth = DateFormatter()
                dfDayOfMonth.dateFormat = "d"
                dayOfMonth = dfDayOfMonth.string(from: date)

                let dfHourMinute = DateFormatter()
                dfHourMinute.dateFormat = "hh:mm a"
                hourMinute = dfHourMinute.string(from: date)
                
                //IF DATE IS LESS THAN CURRENT DATE THEN MAKE THE CELL GREY
                let currentDate = Date()
                if(date < currentDate){
                    inPast = true
                    cell.backgroundColor = UIColor(named: "LightGray")
                }

                print("Day of month: \(dayOfMonth), Time: \(hourMinute)")
            } else {
                print("Invalid date format: \(dateStr)")
            }
        } else {
            print("Date is nil")
        }

        

        if let task = task {
            cell.textLabel?.text = dayOfMonth + ": " + task.taskString
            cell.detailTextLabel?.text = hourMinute
           
            if(!inPast){
                cell.imageView?.image = UIImage(systemName: "calendar")
                cell.imageView?.tintColor = UIColor(named: "white")
            }else{
                cell.imageView?.image = UIImage(systemName: "questionmark.diamond")
                cell.imageView?.tintColor = UIColor(named: "blue")
            }
            
            //let tapGesture = UITapGestureRecognizer(target: self, action: #selector(didTapImageView(_:)))
            
        } else {
            cell.textLabel?.text = "No Task"
            cell.detailTextLabel?.text = ""
        }

        return cell

        
    }
    
//    @objc func didTapImageView(_ sender: UITapGestureRecognizer){
//        guard let tappedView = sender.view else {return}
//        let index = tappedView.tag //index of tapped cell
//
//        //toggle check mark state
//        isChecked[index].toggle()
//
//        //change image based on state
//        if isChecked[index]{
//            tappedView.image = UIImage(systemName: "checkmark.circle.fill")
//        }else{
//            tappedView.image = UIImage(systemName: "circle")
//        }
//
//        tableView.reloadRows(at: [IndexPath(row: index, section: 0)], with: .automatic)
//    }
    
}
