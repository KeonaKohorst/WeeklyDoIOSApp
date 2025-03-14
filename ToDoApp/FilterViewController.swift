import UIKit

class FilterViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    @IBOutlet weak var tableView: UITableView!
    
    let weekdays: [String] = ["All", "Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Finished"]
    let tags: [String] = ["School", "Work", "Fun", "Event", "Chore"]
    
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
        let cell = tableView.dequeueReusableCell(withIdentifier: "DayCell", for: indexPath)
        
        let text: String
        if indexPath.section == 0 {
            text = weekdays[indexPath.row]
        } else {
            text = tags[indexPath.row]
        }
        
        cell.textLabel?.text = text
        cell.textLabel?.font = UIFont.boldSystemFont(ofSize: 19)
        cell.backgroundColor = UIColor(named: "pink")

        // Set icons
        if indexPath.section == 0 {
            if indexPath.row == 0 {
                cell.imageView?.image = UIImage(systemName: "staroflife.fill")
            } else if indexPath.row < 8 {
                cell.imageView?.image = UIImage(systemName: "doc.plaintext")
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
        
        print("Row selected is \(indexPath.row) in section \(indexPath.section)")
        vc.title = "To Do"
        
        
        vc.weekday = selectedCategory
        print("Sending weekday/category \(selectedCategory)")
        navigationController?.pushViewController(vc, animated: true)
    }
}
