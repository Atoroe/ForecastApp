import Foundation

class NetworkManager {
    private init() {}
    static let shared = NetworkManager()
    
    let key = "e45c3399ca3a074064e3b0998a041892"
    let units = "metric"
    
    func getWeather(city: String, complition: @escaping ((ForecastModel?) -> ())) {
        
        guard let url = URL(string: "http://api.openweathermap.org/data/2.5/forecast?id=524901&APPID=\(key)&q=\(city)&units=\(units)") else { return }
        let task = URLSession.shared.dataTask(with: url) { (data, response, error) in
            if let response = response {
                print(response)
            }
            guard let data = data else { return }
            var decoderForecastModel : ForecastModel?
            do {
                decoderForecastModel = try JSONDecoder().decode(ForecastModel.self, from: data)
                complition(decoderForecastModel)
            } catch let error{
                print(error as Any)
            }
        }
        task.resume()
        
    }
    
}
