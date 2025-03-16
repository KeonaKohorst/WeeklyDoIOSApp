//
//  DayTableViewCell.swift
//  ToDoApp
//
//  Created by COSC Student on 2025-03-15.
//

import UIKit

class DayTableViewCell: UITableViewCell {
    
    @IBOutlet weak var dayLabel: UILabel!
    @IBOutlet weak var progressView: UIProgressView!
    @IBOutlet weak var iconImageView: UIImageView!
    
    //called after the view has been loaded meaning i can safely modify the properties of the view
    override func awakeFromNib() {
        super.awakeFromNib()
        progressView.isHidden = true  //hide by default
    }
    
    func configure(with day: String, isCurrentDay: Bool, progress: Float, icon: UIImage?) {
        dayLabel.text = day
        if isCurrentDay {
            progressView.isHidden = false
            progressView.progress = progress
        } else {
            progressView.isHidden = true
        }
        
        iconImageView.image = icon
    }
}

