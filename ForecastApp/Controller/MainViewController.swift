import UIKit
import CoreLocation
import NVActivityIndicatorView

class MainViewController: UIViewController, UITextFieldDelegate {
    
    @IBOutlet weak var locationLabel: UILabel!
    @IBOutlet weak var dayLabel: UILabel!
    @IBOutlet weak var conditionImageView: UIImageView!
    @IBOutlet weak var conditionLabel: UILabel!
    @IBOutlet weak var tempretareLabel: UILabel!
    @IBOutlet weak var forecastTableView: UITableView!
    @IBOutlet weak var searchTextField: UITextField!

    let titles = Titles()
    let locationManager = CLLocationManager()
    let geocoder = CLGeocoder()
    let step = 8
    let dailyCellHeight: CGFloat = 70
    let weeklyCellHeight: CGFloat = 100

    var activityIndicator: NVActivityIndicatorView!
    var dataIsReady = false
    var aditionalDailyData = Array(repeating: Array(repeating: String(), count: 2), count: 3)
    var days = Array(repeating: String(), count: 4)
    var icons = Array(repeating: String(), count: 4)
    var temp = Array(repeating: String(), count: 4)
    var backgroundImageView = UIImageView()
    var regionIdentifier = String()
    var forecastData: ForecastModel? {
        didSet {
            DispatchQueue.main.async {
                guard self.forecastData != nil else { return }
                self.updateData()
                self.forecastTableView.reloadData()
                self.updateMainScreen()
                self.dayUpdate()
                self.activityIndicator.stopAnimating()
                self.backgroundImageView.removeFromSuperview()
                
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.searchTextField.delegate = self
        self.addWallpaper(imageView: self.backgroundImageView)
        self.setupNVActivityIndicatorView()
        self.hideKeyboardWhenTappedAround()
        self.forecastTableView.separatorStyle = .none
        self.locationManager.requestWhenInUseAuthorization()
        if CLLocationManager.locationServicesEnabled() {
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyBest
            locationManager.startUpdatingLocation()
        }
    }
    
    //MARK: - search city
    @IBAction func textFieldEditingChanged(_ sender: UITextField) {
        guard let locality = sender.text else { return }
        if  locality != ""{
            self.activityIndicator.startAnimating()
            self.locationManager.stopUpdatingLocation()
            NetworkManager.shared.getWeather(city: locality) { (model) in
                guard let model = model else { return }
                self.forecastData = model
            }
        } else {
            self.locationManager.startUpdatingLocation()
        }
    }
    
    override func motionEnded(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
        self.locationManager.startUpdatingLocation()
        self.searchTextField.text = ""
    }
    
    //MARK: - create an add wallpaper
    private func addWallpaper(imageView: UIImageView) {
        imageView.frame = CGRect(x: 0,
                                 y: 0,
                                 width: self.view.frame.size.width,
                                 height: self.view.frame.size.height)
        imageView.image = UIImage(named: "background")
        self.view.addSubview(imageView)
    }
    
    //MARK: - updateManeScreen
    private func updateMainScreen() {
        guard let location = forecastData?.city?.name else { return }
        guard let image = forecastData?.list?[0].weather?[0].icon else { return}
        guard let description = forecastData?.list?[0].weather?[0].weatherDescription else { return }
        guard let temp = forecastData?.list?[0].main?.temp else { return }
        self.locationLabel.text = location
        self.dayUpdate()
        self.conditionImageView.image = UIImage(named: image)
        self.conditionLabel.text = description
        self.tempretareLabel.text = "\(Int(temp.rounded(.toNearestOrEven)))"
    }
    
    //MARK: - day update
    private func dayUpdate() {
        let date = Date()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "EEEE"
        self.dayLabel.text = dateFormatter.string(from: date)
    }
    

    
    //MARK: - update all forecast data arrays
    func updateData() {
        updateAdditionalDailyData()
        updateWeeklyData()
    }
    
    private func updateAdditionalDailyData() {
        guard let feelsLike = forecastData?.list?[0].main?.feelsLike else { return }
        guard let pressure = forecastData?.list?[0].main?.pressure else { return }
        guard let humidity = forecastData?.list?[0].main?.humidity else { return }
        guard let windSpeed = forecastData?.list?[0].wind?.speed else { return }
        guard let sunrice = forecastData?.city?.sunrise else { return }
        guard let sunset = forecastData?.city?.sunset else { return }
        let data = ["\(Int(feelsLike.rounded(.toNearestOrEven)))°C",
                    "\(pressure) hPa", "\(humidity)%",
                    "\(self.convertSpeed(speed: windSpeed)) km/h",
                    self.convertUTC(timeResult: sunrice),
                    self.convertUTC(timeResult: sunset)]
        var count = 0
        for row in 0..<self.aditionalDailyData.count{
            for index in 0..<self.aditionalDailyData[row].count {
                self.aditionalDailyData[row][index] = data[count]
                count += 1
            }
        }
    }
    
    private func updateWeeklyData() {
        var count = 0
        for index in 0..<self.days.count {
            count += self.step
            guard let day = forecastData?.list?[count].dt else { return }
            guard let image = forecastData?.list?[count].weather?[0].icon else { return}
            guard let temp = forecastData?.list?[count].main?.temp else { return }
            self.days[index] = self.convertUTC(dayResult: day)
            self.icons[index] = image
            self.temp[index] = "\(Int(temp.rounded(.toNearestOrEven)))"
        }
    }
    
    //MARK: - convert UTC
    func convertUTC(timeResult: Int) -> String {
        let date = Date(timeIntervalSince1970: Double(timeResult))
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "HH:mm"
        let time = dateFormatter.string(from: date)
        return time
    }
    
    func convertUTC(dayResult: Int) -> String {
        let date = Date(timeIntervalSince1970: Double(dayResult))
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "EEEE"
        let day = dateFormatter.string(from: date)
        return day
    }
    
    //MARK: - convert m/c in km/h
    func convertSpeed(speed: Double) -> Int {
        let convertedSpeed = Int(speed * 3600/1000)
        return convertedSpeed
    }
    
    // MARK: - setup NVActivityIndicatorView
    func setupNVActivityIndicatorView(){
        let indicatorSize: CGFloat = 70
        let indicatorFrame = CGRect(x: (view.frame.width-indicatorSize)/2,
                                    y: (view.frame.height-indicatorSize)/2,
                                    width: indicatorSize,
                                    height: indicatorSize)
        self.activityIndicator = NVActivityIndicatorView(frame: indicatorFrame,
                                              type: .ballRotateChase,
                                              color: UIColor.white,
                                              padding: 20.0)
        self.activityIndicator.backgroundColor = UIColor.clear
        self.view.addSubview(self.activityIndicator)
        self.activityIndicator.startAnimating()
    }
    
    //MARK: - hide keyboard after return button pressed
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.view.endEditing(true)
        return false
    }
    
}

// MARK: - UITableView
extension MainViewController: UITableViewDelegate, UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if self.dataIsReady {
            switch section {
            case 0:
                return self.titles.dailyTitles.count
            case 1:
                return self.days.count
            default:
                return self.aditionalDailyData.count
            }
        } else {
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        UITableViewCell.appearance().backgroundColor = UIColor.clear
        if indexPath.section == 0 {
            guard let cell = tableView.dequeueReusableCell(withIdentifier: "DailyCustomTableViewCell", for: indexPath) as? DailyCustomTableViewCell else { return UITableViewCell()
            }
            cell.parameterLabel.text = self.titles.dailyTitles[indexPath.row][0]
            cell.valueLabel.text = self.aditionalDailyData[indexPath.row][0]
            cell.secondParameterLabel.text = self.titles.dailyTitles[indexPath.row][1]
            cell.secondValueLabel.text = self.aditionalDailyData[indexPath.row][1]
            cell.parameterLabel.textColor = UIColor.white
            cell.valueLabel.textColor = UIColor.white
            cell.secondParameterLabel.textColor = UIColor.white
            cell.secondValueLabel.textColor = UIColor.white
            cell.selectionStyle = .none
            return cell
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "WeeklyCustomTableViewCell", for: indexPath) as! WeeklyCustomTableViewCell
            cell.dayLabel.text = self.days[indexPath.row]
            cell.tempLabel.text = " \(self.temp[indexPath.row])°C"
            cell.conditionImageView.image = UIImage(named: self.icons[indexPath.row])
            cell.dayLabel.textColor = UIColor.white
            cell.tempLabel.textColor = UIColor.white
            cell.selectionStyle = .none
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.section == 1 {
            return self.weeklyCellHeight
        }
        return self.dailyCellHeight
    }
}

//MARK: - location
extension MainViewController: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let location = locations[0]
        locationManager.stopUpdatingLocation()
        geocoder.reverseGeocodeLocation(location) { (placemarks, error) in
            if (error != nil) {
                print("Error in reverseGeocode")
            }
            let placemark = placemarks! as [CLPlacemark]
            if placemark.count > 0 {
                guard let placemark = placemarks?[0] else {return}
                guard let locality = placemark.locality else {return}
                NetworkManager.shared.getWeather(city: locality) { (model) in
                    guard let model = model else { return }
                    self.dataIsReady = true
                    self.forecastData = model
                }
            }
        }
    }
}

// MARK: - hide keyboard
extension UIViewController {
    func hideKeyboardWhenTappedAround() {
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(UIViewController.dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }
    
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
}
