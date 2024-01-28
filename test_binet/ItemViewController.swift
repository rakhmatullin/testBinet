//
//  ItemViewController.swift
//  test_binet
//
//  Created by Renat Rakhmatullin on 27.01.2024.
//

import UIKit

struct ItemDataModel: Codable {
    var id: Int
    var image: String
    var name: String
    var description: String
    var documentation: String
}

class ItemViewController: UIViewController {
    private var id: Int
    
    private var bg: UIImageView = {
        let iv = UIImageView()
        iv.translatesAutoresizingMaskIntoConstraints = false
        iv.contentMode = .scaleAspectFit
        iv.clipsToBounds = true
        iv.layer.cornerRadius = 12
        return iv
    }()
    
    private var titleLabel = UILabel()
    private var descriptionLabel = UILabel()
    
    init(id: Int) {
        self.id = id
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(red: 0.435, green: 0.71, blue: 0.294, alpha: 1)
        addSubviews()
        loadData()
    }
    
    private func addSubviews() {
        let backgroundView = UIView()
        view.addSubview(backgroundView)
        backgroundView.backgroundColor = .systemBackground
        backgroundView.translatesAutoresizingMaskIntoConstraints = false
        backgroundView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor).isActive = true
        backgroundView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        backgroundView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        backgroundView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        
        view.addSubview(bg)
        bg.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 12).isActive = true
        bg.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor).isActive = true
        bg.widthAnchor.constraint(equalToConstant: 117).isActive = true
        bg.heightAnchor.constraint(equalToConstant: 183).isActive = true
        
        titleLabel.numberOfLines = 0
        titleLabel.textColor = UIColor(red: 0, green: 0, blue: 0, alpha: 1)
        titleLabel.font = UIFont(name: "Roboto-SemiBold", size: 13)
        view.addSubview(titleLabel)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.topAnchor.constraint(equalTo: bg.bottomAnchor, constant: 16).isActive = true
        titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 12).isActive = true
        titleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -12).isActive = true
        titleLabel.heightAnchor.constraint(lessThanOrEqualToConstant: 133).isActive = true
        
        descriptionLabel.numberOfLines = 0
        descriptionLabel.textColor = UIColor(red: 0.683, green: 0.691, blue: 0.712, alpha: 1)
        descriptionLabel.font = UIFont(name: "Roboto-Regular", size: 12)
        view.addSubview(descriptionLabel)
        descriptionLabel.translatesAutoresizingMaskIntoConstraints = false
        descriptionLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 6).isActive = true
        descriptionLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 12).isActive = true
        descriptionLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -12).isActive = true
        descriptionLabel.bottomAnchor.constraint(lessThanOrEqualTo: view.bottomAnchor, constant: -19).isActive = true
    }
    
    private func loadData() {
        guard let url = URL(string: "http://shans.d2.i-partner.ru/api/ppp/item/?id=\(id)")
        else { return }
        
        let task = URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            guard let self = self else { return }
            
            if let data = data {
                if let dict = try? JSONSerialization.jsonObject(with: data) as? [Any] {
                    print(dict)
                }
                
                do {
                    
                    let decoder = JSONDecoder()
                    let drugResponse = try decoder.decode(ItemDataModel.self, from: data)
                    DispatchQueue.main.async() {
                        self.titleLabel.text = drugResponse.name
                        self.descriptionLabel.text = drugResponse.description
                    }
                    guard let imageUrl = URL(string: "http://shans.d2.i-partner.ru" + drugResponse.image) else { return }
                    URLSession.shared.dataTask(with: imageUrl, completionHandler: { data, response, error in
                        guard let data = data, error == nil else { return }
                        
                        DispatchQueue.main.async() { [weak self] in
                            guard let self = self, let image = UIImage(data: data) else {
                                return
                            }
                            self.bg.image = image
                        }
                    }).resume()
                } catch {
                    print("Ошибка при декодировании JSON: \(error.localizedDescription)")
                }
                
            } else if let error = error {
                print("HTTP Request Failed \(error)")
            }
        }
        task.resume()
    }
}
