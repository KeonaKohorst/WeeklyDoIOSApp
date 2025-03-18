import UIKit
import Foundation

class FilterViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    @IBOutlet weak var tableView: UITableView!
    
    let weekdays: [String] = ["All", "Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Finished"]
    let tags: [String] = ["School", "Work", "Fun", "Event", "Chore"]
    
    var databasePath = String()
    var currentDay: String = ""
    
    let tagIdMap: [String: Int] = [
        "None": 0,
        "School": 1,
        "Work": 2,
        "Fun": 3,
        "Event": 4,
        "Chore": 5
    ]
    
//    var weekdayCounts: [String: Int] = [
//        "All": 0,
//        "Sunday": 0,
//        "Monday": 0,
//        "Tuesday": 0,
//        "Wednesday": 0,
//        "Thursday": 0,
//        "Friday": 0,
//        "Saturday": 0,
//        "Finished": 0
//    ]
//
//    var tagCounts: [String: Int] = [
//        "School": 0,
//        "Work": 0,
//        "Fun": 0,
//        "Event": 0,
//        "Chore": 0
//    ]
    
    var weekdayCounts: [String: Int] = [:]
    var tagCounts: [String: Int] = [:]
    
    @IBOutlet weak var progressView: UIProgressView!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //get the current day
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "EEEE"
        currentDay = dateFormatter.string(from: Date())
        
        // Set delegates
        tableView.dataSource = self
        tableView.delegate = self
        
        // Register a default UITableViewCell
        //tableView.register(UITableViewCell.self, forCellReuseIdentifier: "DayCell")
        
        // Reload table view to reflect data
        tableView.reloadData()
        
        //set up database
        let filemgr = FileManager.default
        let dirPaths = filemgr.urls(for: .documentDirectory, in: .userDomainMask)
        
        databasePath = dirPaths[0].appendingPathComponent("dailydo.db").path
        //print("Filter view controller db path in view did load is \(databasePath)")
        
        if !filemgr.fileExists(atPath: databasePath as String) { //this only runs if there is not already a db file
           print("CREATING THE DB FOR THE FIRST TIME")
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
        
        //get the current days progress
        var percentage = getProgressPercentage()
        percentage = Float(percentage / 100)
        progressView.progress = Float(percentage)
        

        //update the task counts
        updateCounts()
        
        print("VIEW DID LOAD OVER")
    }
    
    override func viewWillAppear(_ animated: Bool){
        super.viewWillAppear(animated)
        //get the current days progress
        var percentage = getProgressPercentage()
        percentage = Float(percentage / 100)
        progressView.progress = Float(percentage)
        
        updateCounts()
       
        
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
            titleLabel.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 16), // Adjust left padding
            titleLabel.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: -16),
            titleLabel.topAnchor.constraint(equalTo: headerView.topAnchor, constant: 4),
            titleLabel.bottomAnchor.constraint(equalTo: headerView.bottomAnchor, constant: -4)
        ])
        
        return headerView
        
    }
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2  // One for weekdays, one for tags
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return section == 0 ? weekdays.count : tags.count
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return section == 0 ? "Weekdays" : "Tags"
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "DayCell") ?? UITableViewCell(style: .value1, reuseIdentifier: "DayCell")
        
        let text: String
        var count = 0
        if indexPath.section == 0 {
            text = weekdays[indexPath.row]
            if(text == "All"){
                //count = getTotalUnfinishedTasks()
                //print("total tasks are \(count)")
                
                count = weekdayCounts[text]!
            }else if(text == "Finished"){
                //count = getTotalFinishedTasks()
                count = weekdayCounts[text]!
                
            }else{
                //let weekdayID = getIdForWeekday(name: text)
                //count = getCountByWeekday(weekdayID: weekdayID)
                //print("count for \(text) is \(count)")
                count = weekdayCounts[text]!
            }
            print("count for \(text) is \(count)")
            
        } else {
            text = tags[indexPath.row]
            let tagID = tagIdMap[text]
            //count = getCountByTag(tagID: tagID!)
            //print("count for \(text) is \(count)")
            count = tagCounts[text]!
        }
        
    
  
        cell.detailTextLabel?.text = "\(count)"
        cell.detailTextLabel?.font = UIFont.boldSystemFont(ofSize: 15)
        
        cell.textLabel?.text = text
        cell.textLabel?.font = UIFont.boldSystemFont(ofSize: 19)
        
        cell.backgroundColor = UIColor(named: "pink")

        // Set icons
        if indexPath.section == 0 {
            if indexPath.row == 0 {
                cell.imageView?.image = UIImage(systemName: "staroflife.fill")
            } else if indexPath.row < 8 {
                if(text == currentDay){
                    print("Current day is  \(currentDay)")
                    cell.imageView?.image = UIImage(systemName: "mappin.and.ellipse")
                }else{
                    cell.imageView?.image = UIImage(systemName: "doc.plaintext")
                }
            } else {
                cell.imageView?.image = UIImage(systemName: "checkmark.circle.fill")
            }
        } else {
            if(indexPath.row == 0){
                cell.imageView?.image = UIImage(systemName: "book.fill")
            }else if(indexPath.row == 1){
                cell.imageView?.image = UIImage(systemName: "briefcase.fill")
            }else if(indexPath.row == 2){
                cell.imageView?.image = UIImage(systemName: "smiley.fill")
            }else if(indexPath.row == 3){
                cell.imageView?.image = UIImage(systemName: "burst.fill")
            }else if(indexPath.row == 4){
                cell.imageView?.image = UIImage(systemName: "house.fill")
            }
            
        }
        cell.imageView?.tintColor = UIColor(named: "white")
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let vc = storyboard?.instantiateViewController(identifier: "list") as! ViewController
        
        let selectedCategory = indexPath.section == 0 ? weekdays[indexPath.row] : tags[indexPath.row]
        
        //print("Row selected is \(indexPath.row) in section \(indexPath.section)")
        vc.title = "To Do"
        
        
        vc.weekday = selectedCategory
        print("Sending weekday/category \(selectedCategory)")
        navigationController?.pushViewController(vc, animated: true)
    }
    
    func getProgressPercentage() -> Float {
        let dailyDoDB = FMDatabase(path: databasePath as String)
        
        if (dailyDoDB.open()) {
            let id = getIdForWeekday(name: currentDay)
            var totalTasksForDay = 0
            var totalFinishedTasksForDay = 0
            
            var getSQL = "SELECT COUNT(*) AS count FROM Tasks WHERE weekday = '\(id)'"
            if let result = dailyDoDB.executeQuery(getSQL, withArgumentsIn: []) {
                if result.next() { // move to the first row with .next()
                    totalTasksForDay = Int(result.int(forColumn: "count"))
                    
                    
                } else {
                    print("Get progress percentage: No tasks for weekday \(currentDay)")
                }
            } else {
                print("Failed to fetch total tasks for day: \(dailyDoDB.lastErrorMessage())")
            }
            
            getSQL = "SELECT COUNT(*) AS count FROM Tasks WHERE weekday = '\(id)' AND finished = true"
            if let result = dailyDoDB.executeQuery(getSQL, withArgumentsIn: []) {
                if result.next() { // move to the first row with .next()
                    totalFinishedTasksForDay = Int(result.int(forColumn: "count"))
                    
                    
                } else {
                    print("Get progress percentage: No FINISHED tasks for weekday \(currentDay)")
                }
            } else {
                print("Failed to fetch total finished tasks for day: \(dailyDoDB.lastErrorMessage())")
            }
            
            print("Total tasks for \(currentDay) is \(totalTasksForDay)")
            print("Total FINISHED tasks for \(currentDay) is \(totalFinishedTasksForDay)")
            
            if(totalTasksForDay != 0){
                let percentage = Float((Float(totalFinishedTasksForDay) / Float(totalTasksForDay)) * 100)
                print("Percentage for \(currentDay) is \(percentage)")
                
                
                return percentage
            }else{
                return 100.0
            }
            
        }else{
            print("Failed to open DB")
            
        }
        return 100.0
    }
    
    func getIdForWeekday(name: String) -> Int {
        // Get weekday from the ID
        //print("Get weekday by id: \(id)")
        let dailyDoDB = FMDatabase(path: databasePath as String)
        //print("Database path: \(databasePath)")

        if (dailyDoDB.open()) {
            //print("OPENED DB")
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
    
    func getCountByWeekday(weekdayID: Int) -> Int {
        // Get weekday from the ID
        //print("Get weekday by id: \(id)")
        let dailyDoDB = FMDatabase(path: databasePath as String)
        //print("Database path: \(databasePath)")

        if (dailyDoDB.open()) {
            //print("OPENED DB")
            let getSQL = "SELECT COUNT(*) AS count FROM tasks WHERE weekday = '\(weekdayID)' AND finished = false"
            if let result = dailyDoDB.executeQuery(getSQL, withArgumentsIn: []) {
                if result.next() { // move to the first row with .next()
                    let count = Int(result.int(forColumn: "count"))
                    
                    return count
                } else {
                    print("Get count for weekday function: No matching weekday id found for name \(weekdayID)")
                }
            } else {
                print("Failed to fetch count by weekday: \(dailyDoDB.lastErrorMessage())")
            }
        }else{
            print("Failed to open DB")
            
        }
        return 0
        
    }
    
    func getCountByTag(tagID: Int) -> Int {
        // Get weekday from the ID
        //print("Get weekday by id: \(id)")
        let dailyDoDB = FMDatabase(path: databasePath as String)
        //print("Database path: \(databasePath)")

        if (dailyDoDB.open()) {
            //print("OPENED DB")
            let getSQL = "SELECT COUNT(*) AS count FROM tasks WHERE weekday = '\(tagID)' AND finished = false"
            if let result = dailyDoDB.executeQuery(getSQL, withArgumentsIn: []) {
                if result.next() { // move to the first row with .next()
                    let count = Int(result.int(forColumn: "count"))
                    
                    return count
                } else {
                    print("Get count for tag function: Nothing found for tag \(tagID)")
                }
            } else {
                print("Failed to fetch count by tag: \(dailyDoDB.lastErrorMessage())")
            }
        }else{
            print("Failed to open DB")
            
        }
        return 0
        
    }
    
    func updateCounts() {
        print("UPDATING COUNTS")
        weekdayCounts.removeAll()
        tagCounts.removeAll()
        
        // Get the counts
        for day in weekdays {
            let count: Int
            switch day {
            case "All":
                count = getTotalUnfinishedTasks()
            case "Finished":
                count = getTotalFinishedTasks()
            default:
                let weekdayID = getIdForWeekday(name: day)
                count = getCountByWeekday(weekdayID: weekdayID)
                
            }
            //weekdayCounts[day] = count
            if weekdayCounts[day] == nil {
                weekdayCounts[day] = 0
            }
            weekdayCounts[day]? = count
            print("\(day) has count \(count)")
            
        }
        
        for tag in tags {
            if tag != "None", let tagID = tagIdMap[tag] {
                tagCounts[tag] = getCountByTag(tagID: tagID)
            }
        }
        
        tableView.reloadData()
    }

    
    func getTotalUnfinishedTasks() -> Int {
        // Get weekday from the ID
        //print("Get weekday by id: \(id)")
        let dailyDoDB = FMDatabase(path: databasePath as String)
        //print("Database path: \(databasePath)")

        if (dailyDoDB.open()) {
            //print("OPENED DB")
            let getSQL = "SELECT COUNT(*) AS count FROM tasks WHERE finished = false;"
            if let result = dailyDoDB.executeQuery(getSQL, withArgumentsIn: []) {
                if result.next() { // move to the first row with .next()
                    let count = Int(result.int(forColumn: "count"))
                    
                    return count
                } else {
                    print("Get total count returned nothing")
                }
            } else {
                print("Failed to fetch count by weekday: \(dailyDoDB.lastErrorMessage())")
            }
        }else{
            print("Failed to open DB")
            
        }
        return 0
        
    }
    
    func getTotalFinishedTasks() -> Int {
        // Get weekday from the ID
        //print("Get weekday by id: \(id)")
        let dailyDoDB = FMDatabase(path: databasePath as String)
        //print("Database path: \(databasePath)")

        if (dailyDoDB.open()) {
            //print("OPENED DB")
            let getSQL = "SELECT COUNT(*) AS count FROM tasks WHERE finished = true;"
            if let result = dailyDoDB.executeQuery(getSQL, withArgumentsIn: []) {
                if result.next() { // move to the first row with .next()
                    let count = Int(result.int(forColumn: "count"))
                    
                    return count
                } else {
                    print("Get total count returned nothing")
                }
            } else {
                print("Failed to fetch count by weekday: \(dailyDoDB.lastErrorMessage())")
            }
        }else{
            print("Failed to open DB")
            
        }
        return 0
        
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
}
