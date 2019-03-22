import Vapor

/// Register your application"s routes here.
public func routes(_ router: Router) throws {
    // Basic "It works" example
    router.get { req in
        return "It works!"
    }
    
    // Basic "Hello, world!" example
    router.get("hello") { req in
        return "Hello, world!"
    }

    router.post("delivery") { request -> String in
        guard let bodyData = request.http.body.data, let body = String(data: bodyData, encoding: .utf8) else {
            return "DELIVERY - Invalid data"
        }
        print("DELIVERY - request body: \(body)")
        return "OK"
    }
    
    router.post("inbound") { request -> String in
        guard let bodyData = request.http.body.data, let body = String(data: bodyData, encoding: .utf8) else {
            return "Invalid data"
        }
        
        guard let msisdn = try? request.content.syncGet(String.self, at: "msisdn"),
            let keyword = try? request.content.syncGet(String.self, at: "keyword") else {
                return "bad data"
        }
        switch keyword.lowercased() {
        case "hello":
            NexmoMessage.send(to: msisdn, message: "Hello World")
        case "emoji":
            NexmoMessage.send(to: msisdn, message: "Have a Free Puppy 🐶", type: "unicode")
        case "unicode":
            NexmoMessage.send(to: msisdn, message:"Are you getting your 5 a day 🍌🌽🍊🍏🍒", type: "unicode")
        case "long":
            NexmoMessage.send(to: msisdn, message: "Bacon ipsum dolor amet tail bresaola pork loin kielbasa sirloin pancetta. Pork chop bacon beef ribs, picanha t-bone ground round kevin drumstick prosciutto corned beef. Prosciutto tongue capicola, t-bone biltong turducken tail pastrami ham doner. Bacon beef ribs ham hock chuck kielbasa tongue boudin tenderloin shoulder pastrami short loin leberkas kevin drumstick. Meatloaf pig pork loin tri-tip ball tip. Turducken venison leberkas kielbasa boudin ball tip, sausage tenderloin beef ribs short loin frankfurter. Corned beef pork picanha bresaola sausage.", from: "iOSCon")
        case "flash":
            NexmoMessage.send(to: msisdn, message:"Look Ma! No hands!", messageClass: "0")
        case "voicemail":
            NexmoMessage.sendBinary(to: msisdn, udh: "0401028099", body : "")
        case "clear":
            NexmoMessage.sendBinary(to: msisdn, udh: "0401020000", body: "")
        case "show":
            NexmoMessage.sendBinary(to: msisdn, udh: "050003CC0101", body: "57494E", protocolId: "65")
        case "replace":
            NexmoMessage.sendBinary(to: msisdn, udh: "050003CC0101", body: "4C4F5345",  protocolId: "65")
        default:
            NexmoMessage.send(to: msisdn, message: "hello")
        }
        return "OK"
    }

}


class NexmoMessage {
    static let apiKey = "YOUR API KEY"
    static let apiSecret = "YOUR API SECRET"
    static let url = URL(string: "https://rest.nexmo.com/sms/json")
    
    static func send(to recipient: String, message: String, from: String? = nil, type: String? = nil, messageClass: String? = nil) {
        guard let smsUrl = url else { return }
        
        var request = URLRequest(url: smsUrl)
        request.httpMethod = "POST"
        
        var urlParser = URLComponents()
        urlParser.queryItems = [
            URLQueryItem(name: "from", value: from ?? "YOUR NUMBER"),
            URLQueryItem(name: "text", value: message),
            URLQueryItem(name: "to", value: recipient),
            URLQueryItem(name: "api_key", value: apiKey),
            URLQueryItem(name: "api_secret", value: apiSecret)
        ]
        if let type = type {
            urlParser.queryItems?.append(URLQueryItem(name: "type", value: type))
        }
        if let messageClass = messageClass {
            urlParser.queryItems?.append(URLQueryItem(name: "message-class", value: messageClass))
        }
        let httpBodyString = urlParser.percentEncodedQuery
        request.httpBody = httpBodyString?.data(using: .utf8)
    
        let task = URLSession.shared.dataTask(with: request) {
            (data, response, error) in
            guard error == nil else {
                print("error calling POST")
                print(error!)
                return
            }
            guard let responseData = data else {
                print("Error: did not receive data")
                return
            }
            print(responseData)
        }
        task.resume()
        
    }
    static func sendBinary(to recipient: String, udh: String, body: String, from: String? = nil, protocolId: String? = nil) {
        guard let smsUrl = url else { return }
        
        var request = URLRequest(url: smsUrl)
        request.httpMethod = "POST"
        
        var urlParser = URLComponents()
        urlParser.queryItems = [
            URLQueryItem(name: "from", value: from ?? "YOUR NUMBER"),
            URLQueryItem(name: "to", value: recipient),
            URLQueryItem(name: "api_key", value: apiKey),
            URLQueryItem(name: "api_secret", value: apiSecret),
            URLQueryItem(name: "body", value: body),
            URLQueryItem(name: "udh", value: udh),
            URLQueryItem(name: "type", value: "binary")
        ]
        if let protocolId = protocolId {
            urlParser.queryItems?.append(URLQueryItem(name: "protocol-id", value: protocolId))
        }
        let httpBodyString = urlParser.percentEncodedQuery
        request.httpBody = httpBodyString?.data(using: .utf8)
        
        let task = URLSession.shared.dataTask(with: request) {
            (data, response, error) in
            guard error == nil else {
                print("error calling POST")
                print(error!)
                return
            }
            guard let responseData = data else {
                print("Error: did not receive data")
                return
            }
            print(responseData)
        }
        task.resume()
    }
    
}
