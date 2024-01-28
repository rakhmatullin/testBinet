//
//  ViewController.swift
//  test_binet
//
//  Created by Renat Rakhmatullin on 23.01.2024.
//

import UIKit

struct Fields: Codable {
    // Поля для наборных полей
    // Замените на реальные типы данных, соответствующие вашему API
    let fieldName: String
    let fieldValue: String
}
struct DrugsCategories: Codable {
    // Заменяем существующие поля
//    let id: Int
//    let icon: String
//    let image: String
//    let name: String
    
    // Другие поля категорий, если они есть
}
struct Drugs: Codable {
    let id: Int
    let image: String
//    var categories: [DrugsCategories]?
    let name: String
    let description: String
//    let documentation: String?
//    let linkToDocumentation: String  // ссылка на документацию
    
//    let fields: [Fields]?
}

struct DrugsResponse: Codable {
    let drugs: [Drugs]
}

final class ViewController: UIViewController, UISearchBarDelegate {
    private var collectionView = UICollectionView(frame: .zero, collectionViewLayout: UICollectionViewFlowLayout())
    
    var collectionItems: [(Int, UIImage?, String, String)] = []
    
    var pageSize = 0
    var currentPage = 0
    var lastDownloadedPageSize = 0 {
        didSet {
            if lastDownloadedPageSize < pageSize {
                hasLoader = false
            }
        }
    }
    var isLoading = false
    var hasLoader = true
    
    var searchText: String = ""
//    var isFiltered: Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationController?.navigationBar.backgroundColor = UIColor(red: 0.435, green: 0.71, blue: 0.294, alpha: 1)
        let textAttributes = [NSAttributedString.Key.foregroundColor:UIColor.white]
        navigationController?.navigationBar.titleTextAttributes = textAttributes
        navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "magnifyingglass")?.withTintColor(UIColor.white, renderingMode: .alwaysOriginal), style: .plain, target: self, action: #selector(selectorName))
        title = "Препараты"
        
        view.backgroundColor = UIColor(red: 0.435, green: 0.71, blue: 0.294, alpha: 1)
        addSubviews()
        pageSize = Int(view.bounds.height / 297) * Int((view.bounds.height - view.safeAreaInsets.bottom - view.safeAreaInsets.top) / 157)
        downloadData()
    }
    
    @objc func selectorName() {
        let search = UISearchController(searchResultsController: nil)
        search.delegate = self
        search.searchBar.delegate = self
        navigationItem.searchController = search
    }
    
    private func addSubviews() {
        collectionView.backgroundColor = .systemBackground
        collectionView.register(CustomCell.self, forCellWithReuseIdentifier: "cell")
        collectionView.register(IndicatorCell.self, forCellWithReuseIdentifier: "indicator")
        collectionView.dataSource = self
        collectionView.delegate = self
        view.addSubview(collectionView)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor).isActive = true
        collectionView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor).isActive = true
        collectionView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor).isActive = true
        collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
    }
    
    @objc private func loadData() {
        guard !isLoading else {
            return
        }
        currentPage += 1
        
        guard let url = URL(string: "http://shans.d2.i-partner.ru/api/ppp/index/?offset=\(2 * currentPage * pageSize)&limit=\(pageSize)")
        else { return }
        
        isLoading = true
        let task = URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            guard let self = self else { return }
            
            if let data = data {
                if let dict = try? JSONSerialization.jsonObject(with: data) as? [Any] {
                    print(dict)
//                  completion(.success(dict))
                } else {
//                  completion(.failure(
//                    .JSONParseError("Failed to parse JSON to dictionary")
//                  ))
                }
                
                do {
                    let group = DispatchGroup()
                    let decoder = JSONDecoder()
                    let drugsResponse = try decoder.decode([Drugs].self, from: data)
                    var newCollectionItems: [(Int, UIImage?, String, String)] = []
                    lastDownloadedPageSize = drugsResponse.count
                    print(drugsResponse)
                    for drugResponse in drugsResponse {
                        guard let imageUrl = URL(string: "http://shans.d2.i-partner.ru" + drugResponse.image) else { continue }
                        group.enter()
                        URLSession.shared.dataTask(with: imageUrl, completionHandler: { data, response, error in
                            guard let data = data, error == nil else { return }
                            
                            DispatchQueue.main.async() {
                                guard let image = UIImage(data: data) else {
                                    return
                                }
                                newCollectionItems.append((drugResponse.id, image, drugResponse.name, drugResponse.description))
                                group.leave()
                            }
                        }).resume()
                    }
                    group.notify(queue: DispatchQueue.main, execute: { [weak self] in
                        guard let self = self else { return }
                        collectionItems = collectionItems + newCollectionItems
                        isLoading = false
                        collectionView.reloadData()
                    })
                } catch {
                    print("Ошибка при декодировании JSON: \(error.localizedDescription)")
                }

//                let image = UIImage(data: data)
                
            } else if let error = error {
                print("HTTP Request Failed \(error)")
            }
        }
        task.resume()
    }
    
    private func downloadData() {
        guard !isLoading else {
            return
        }
        
        // http://shans.d2.i-partner.ru/api/ppp/index/?offset=10&limit=10
        let initialSize = pageSize * 2
        currentPage = 1
        guard let url = URL(string: "http://shans.d2.i-partner.ru/api/ppp/index/?offset=\(0)&limit=\(initialSize)")
        else { return }

        isLoading = true
        let task = URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            guard let self = self else { return }
            
            if let data = data {
                if let dict = try? JSONSerialization.jsonObject(with: data) as? [Any] {
                    print(dict)
//                  completion(.success(dict))
                } else {
//                  completion(.failure(
//                    .JSONParseError("Failed to parse JSON to dictionary")
//                  ))
                }
                
                do {
                    let group = DispatchGroup()
                    let decoder = JSONDecoder()
                    let drugsResponse = try decoder.decode([Drugs].self, from: data)
                    var newCollectionItems: [(Int, UIImage?, String, String)] = []
                    lastDownloadedPageSize = drugsResponse.count
                    for drugResponse in drugsResponse {
                        guard let imageUrl = URL(string: "http://shans.d2.i-partner.ru" + drugResponse.image) else { continue }
                        group.enter()
                        URLSession.shared.dataTask(with: imageUrl, completionHandler: {
                            data, response, error in
                            guard let data = data, error == nil else { return }
                            print(response?.suggestedFilename ?? url.lastPathComponent)
                            print("Download Finished")
                            DispatchQueue.main.async() { // [weak self] in
    //                            self?.imageView.image =
                                guard let image = UIImage(data: data) else {
                                    return
                                }
                                newCollectionItems.append((drugResponse.id, image, drugResponse.name, drugResponse.description))
//                                self.images.append(image)
                                group.leave()
                            }
                        }).resume()
                    }
                    group.notify(queue: DispatchQueue.main, execute: { [weak self] in
                        guard let self = self else { return }
                        isLoading = false
                        collectionItems = newCollectionItems
                        collectionView.reloadData()
                    })
                } catch {
                    print("Ошибка при декодировании JSON: \(error.localizedDescription)")
                }

//                let image = UIImage(data: data)
                
            } else if let error = error {
                print("HTTP Request Failed \(error)")
            }
        }
        task.resume()
    }
    
    private func downloadDataWithFilter(searchText: String) {
//        currentPage += 1
        
        guard let url = URL(string: "http://shans.d2.i-partner.ru/api/ppp/index/?offset=\(2 * currentPage * pageSize)&limit=\(pageSize)&search=\(searchText)")
        else { return }
        
        isLoading = true
        let task = URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            guard let self = self else { return }
            
            if let data = data {
//                if let dict = try? JSONSerialization.jsonObject(with: data) as? [Any] {
//                    print(dict)
////                  completion(.success(dict))
//                } else {
////                  completion(.failure(
////                    .JSONParseError("Failed to parse JSON to dictionary")
////                  ))
//                }
                // TODO: CHECK that the search string in answer is the same as in the field now
                collectionItems = []
                currentPage = 1
                hasLoader = true
                
//                var searchText: String = ""
//                var isFiltered: Bool = false
                
                do {
                    let group = DispatchGroup()
                    let decoder = JSONDecoder()
                    let drugsResponse = try decoder.decode([Drugs].self, from: data)
                    var newCollectionItems: [(Int, UIImage?, String, String)] = []
                    lastDownloadedPageSize = drugsResponse.count
                    print(drugsResponse)
                    for drugResponse in drugsResponse {
                        guard let imageUrl = URL(string: "http://shans.d2.i-partner.ru" + drugResponse.image) else { continue }
                        group.enter()
                        URLSession.shared.dataTask(with: imageUrl, completionHandler: { data, response, error in
                            guard let data = data, error == nil else { return }
                            
                            DispatchQueue.main.async() {
                                guard let image = UIImage(data: data) else {
                                    return
                                }
                                newCollectionItems.append((drugResponse.id, image, drugResponse.name, drugResponse.description))
                                group.leave()
                            }
                        }).resume()
                    }
                    group.notify(queue: DispatchQueue.main, execute: { [weak self] in
                        guard let self = self else { return }
                        collectionItems = collectionItems + newCollectionItems
                        isLoading = false
                        collectionView.reloadData()
                    })
                } catch {
                    print("Ошибка при декодировании JSON: \(error.localizedDescription)")
                }

//                let image = UIImage(data: data)
                
            } else if let error = error {
                print("HTTP Request Failed \(error)")
            }
        }
        task.resume()
    }
    
}

extension ViewController: UISearchControllerDelegate {
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        self.searchText = ""
//        self.isFiltered = false
        self.collectionView.reloadData()
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        self.searchText = searchText
        downloadDataWithFilter(searchText: searchText)
//        print(searchText)
    }
}

extension ViewController: UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        collectionItems.count == indexPath.row ? CGSize(width: collectionView.frame.size.width, height: 40) : CGSize(width: 157, height: 297)
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        collectionItems.count > 0 ? (collectionItems.count + (hasLoader ? 1 : 0)) : 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if indexPath.row == collectionItems.count {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "indicator", for: indexPath) as! IndicatorCell
            cell.inidicator.startAnimating()
            return cell
        } else {
            let cell = collectionView.dequeueReusableCell (withReuseIdentifier: "cell", for: indexPath) as! CustomCell
            cell.bg.image = collectionItems[indexPath.row].1
            cell.titleLabel.text = collectionItems[indexPath.row].2
            cell.descriptionLabel.text = collectionItems[indexPath.row].3
            return cell
        }
        
    }
    
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        if indexPath.row == collectionItems.count && lastDownloadedPageSize >= pageSize {
            loadData()
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard indexPath.row < collectionItems.count else { return }
        
        let itemVC = ItemViewController(id: collectionItems[indexPath.row].0)
        navigationController?.pushViewController(itemVC, animated: true)
    }
}

class CustomCell: UICollectionViewCell {
    fileprivate var bg: UIImageView = {
        let iv = UIImageView()
        iv.translatesAutoresizingMaskIntoConstraints = false
        iv.contentMode = .scaleAspectFit
        iv.clipsToBounds = true
        iv.image = UIImage(systemName: "plus")
        iv.layer.cornerRadius = 12
        return iv
    }()
    
    var titleLabel = UILabel()
    var descriptionLabel = UILabel()
    
    override init(frame: CGRect) {
        super.init(frame: .zero)
        contentView.addSubview(bg)
        bg.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12).isActive = true
        bg.centerXAnchor.constraint(equalTo: contentView.centerXAnchor).isActive = true
        bg.widthAnchor.constraint(equalToConstant: 133).isActive = true
        bg.heightAnchor.constraint(equalToConstant: 78).isActive = true
        
        titleLabel.numberOfLines = 0
        titleLabel.textColor = UIColor(red: 0, green: 0, blue: 0, alpha: 1)
        titleLabel.font = UIFont(name: "Roboto-SemiBold", size: 13)
        contentView.addSubview(titleLabel)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.topAnchor.constraint(equalTo: bg.bottomAnchor, constant: 16).isActive = true
        titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 12).isActive = true
        titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -12).isActive = true
        titleLabel.heightAnchor.constraint(lessThanOrEqualToConstant: 133).isActive = true
        
        descriptionLabel.numberOfLines = 0
        descriptionLabel.textColor = UIColor(red: 0.683, green: 0.691, blue: 0.712, alpha: 1)
        descriptionLabel.font = UIFont(name: "Roboto-Regular", size: 12)
        contentView.addSubview(descriptionLabel)
        descriptionLabel.translatesAutoresizingMaskIntoConstraints = false
        descriptionLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 6).isActive = true
        descriptionLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 12).isActive = true
        descriptionLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -12).isActive = true
        descriptionLabel.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor, constant: -19).isActive = true
//        descriptionLabel.heightAnchor.constraint(lessThanOrEqualToConstant: 133).isActive = true
//        bg.leadingAnchor.constraint(equalTo: contentView.leadingAnchor).isActive = true
//        bg.trailingAnchor.constraint(equalTo: contentView.trailingAnchor).isActive = true
//        bg.bottomAnchor.constraint(equalTo: contentView.bottomAnchor).isActive = true
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}


class IndicatorCell: UICollectionViewCell {
    
    var inidicator : UIActivityIndicatorView = {
        let view = UIActivityIndicatorView()
        view.style = .large
        return view
    }()
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }
    
    func setup(){
        contentView.addSubview(inidicator)
        inidicator.translatesAutoresizingMaskIntoConstraints = false
        inidicator.centerXAnchor.constraint(equalTo: contentView.centerXAnchor).isActive = true
        inidicator.centerYAnchor.constraint(equalTo: contentView.centerYAnchor).isActive = true
        inidicator.startAnimating()
    }
    
}
