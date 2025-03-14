//
//  FilterViewController.swift
//  ToDoApp
//
//  Created by COSC Student on 2025-03-11.
//
import UIKit

class FilterViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    @IBOutlet weak var tableView: UITableView!
    
    var weekdays: [String] = ["All", "Sunday", "Monday", "Tuesday", "Wednesday",  "Thursday", "Friday", "Saturday", "Finished"]
    

    
    //based on the ids in the database, should probably query for these
    //to populate this array
    //var weekdayIDs: [String] = ["0", "2", "1", "3", "4", "5", "6", "7", "8"]

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set delegates
        tableView.dataSource = self
        tableView.delegate = self
        
        // Register a default UITableViewCell
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "DayCell")
        
        
        
        // Reload table view to reflect data
        tableView.reloadData()
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return weekdays.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "DayCell", for: indexPath)
        cell.textLabel?.text = weekdays[indexPath.row]
        cell.backgroundColor = (indexPath.row == 8) ? UIColor(named: "pink") : UIColor(named: "pink")
        if let label = cell.textLabel{
        
            label.font = UIFont.boldSystemFont(ofSize: 19)
        }
        
        if(indexPath.row == 0){
            cell.imageView?.image = UIImage(systemName: "staroflife.fill")
            cell.imageView?.tintColor = UIColor(named: "white")
            
        }
        
        if(indexPath.row > 0 && indexPath.row < 8){
            cell.imageView?.image = UIImage(systemName: "doc.plaintext")
            cell.imageView?.tintColor = UIColor(named: "white")
            
        }
        
        if(indexPath.row == 8){
            //add icon
            cell.imageView?.image = UIImage(systemName: "checkmark.circle.fill")
            cell.imageView?.tintColor = UIColor(named: "white")
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath){
        tableView.deselectRow(at: indexPath, animated: true)
        
        let vc = storyboard?.instantiateViewController(identifier: "list") as! ViewController
        
        print("Row selected is \(indexPath.row)")
        vc.title = "To Do"
        vc.weekday = weekdays[indexPath.row]
        print("Sending weekday/category \(weekdays[indexPath.row])")
        navigationController?.pushViewController(vc, animated: true)
    }
    
}



