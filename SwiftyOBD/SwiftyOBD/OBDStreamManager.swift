//
//  OBDStreamHelper.swift
//  SwiftyOBD-Example
//
//  Created by Daniel Montano on 06.10.16.
//  Copyright © 2016 Hella Ventures Berlin. All rights reserved.
//

import Foundation
//import XCGLogger

protocol OBDStreamManagerDelegate{
    func DTCsUpdated(_ newDTCs: [String], dtcs: Int)
    func setupProgress(_ progress: Double)
    func disconnected()
}
// Create an extension for the protocol so we can create optional functions without using "@objc optional"
extension OBDStreamManagerDelegate {
    func DTCsUpdated(_ newDTCs: [String], dtcs: Int){}
    func setupProgress(_ progress: Double){}
    func disconnected(){}
}

class OBDStreamManager: NSObject, StreamDelegate {
    
    //SINGLETON INSTANCE
    static let sharedInstance = OBDStreamManager()
    
    //DELEGATE
    var delegate: OBDStreamManagerDelegate?
    
    //ELM327 PROTOCOL
    var obdProtocol: ELM327.PROTOCOL = .NONE //Will be determined by the setup
    fileprivate var timeout: Double = 0.0
    
    //PARSING
    fileprivate let parser = OBDParser.sharedInstance
    fileprivate var linesToParse: [String] = []
    fileprivate var parserResponse: (Bool, [String]) = (false, [])
    
    //STREAM
    fileprivate var connection: OBDConnection?
    fileprivate var buffer: [UInt8]?
    fileprivate var len: Int = 0
    
    fileprivate var connectionEstablished = false
    fileprivate var readyToSend = true
    fileprivate var currentQuery: ELM327.QUERY = .NONE
    
    //SETUP
    fileprivate var currentSetupStepReady = false
    fileprivate var setupInProgress = false
    fileprivate var setupStatus: ELM327.QUERY.SETUP_STEP = .none
    fileprivate var setupFinished = false
    fileprivate var setupTimer: Timer?
    
    //DTCs
    fileprivate var currentGetDTCsQueryReady = false
    fileprivate var getDTCsStatus: ELM327.QUERY.GET_DTCS_STEP = .none
    fileprivate var requestingDTCs: Bool = false
    fileprivate var currentDTCs: [String] = []
    fileprivate var numberOfDTCs: Int = 0
    fileprivate var getDTCsTimer: Timer?
    
    fileprivate override init(){
        super.init()
    }
    
    ////////////////////////////////////////////////////////
    // MARK: CONNECTION RELEVANT STUFF
    ////////////////////////////////////////////////////////
    
    func connect(_ connection: OBDConnection = OBDConnection()){
        
        Stream.getStreamsToHost(withName: connection.host,
                                          port: connection.port,
                                          inputStream: &connection.inputStream,
                                          outputStream: &connection.outputStream)
        
        connection.inputStream!.delegate = self
        connection.outputStream!.delegate = self
        
        connection.inputStream!.schedule(in: RunLoop.current, forMode: RunLoopMode.defaultRunLoopMode)
        connection.outputStream!.schedule(in: RunLoop.current, forMode: RunLoopMode.defaultRunLoopMode)
        
        connection.inputStream!.open()
        connection.outputStream!.open()
        
        buffer = connection.buffer
        
        self.connection = connection
        
    }
    
    
    func disconnect(){
        if let connection = self.connection {
            connection.inputStream!.close()
            connection.inputStream!.remove(from: RunLoop.current, forMode: RunLoopMode.defaultRunLoopMode)
            connection.outputStream!.close()
            connection.outputStream!.remove(from: RunLoop.current, forMode: RunLoopMode.defaultRunLoopMode)
        }
    }
    
    func startStreaming(connection: OBDConnection = OBDConnection()){
        disconnect()
        connect(connection)
    }
    
    func stream(_ aStream: Stream, handle eventCode: Stream.Event) {
        
        if let connection = connection {
            
            switch eventCode {
                
            case Stream.Event.openCompleted:
                log.debug("Stream opened")
                self.readyToSend = true
                self.connectionEstablished = true
                break
            case Stream.Event.hasBytesAvailable:
                
                if(aStream == connection.inputStream){
                    
                    while(connection.inputStream!.hasBytesAvailable){
                        len = connection.inputStream!.read(&connection.buffer, maxLength: connection.buffer.count)
                        if len > 0 {
                            
                            let serverOutput = NSString(bytes: &connection.buffer, length: len, encoding: String.Encoding.ascii.rawValue)
                            
                            if let output = serverOutput {
                                log.debug("NSStream has Bytes available. \nServer said: \n\(output)")
                                
                                output.enumerateLines({line, stop in
                                    
                                    if line.contains("00A") {
                                        return
                                    }
                                    
                                    self.linesToParse.append(line)
                                    
                                    if line.contains(">") {
                                        
                                        self.parseResponse() //Here is the parsing part itself, ofc using the parser
                                        self.evaluateResponse() //Here is the logic based on the parser response
                                        
                                        self.linesToParse.removeAll()
                                        self.readyToSend = true
                                    }
//                                    if (line.characters.count < 5 && !line.containsString(">")){
//                                        return
//                                    }
                                })
                                
                                if !output.contains("SEARCHING...\r") {
                                    self.readyToSend = true
                                }
                            }
                        }
                    }
                }
                break
            case Stream.Event.errorOccurred:
                log.error("NSStream Error Occurred.")
                connectionEstablished = false
                readyToSend = false
                delegate?.disconnected()
                disconnect()
                break
            case Stream.Event.endEncountered:
                log.warning("NSStream End Encountered.")
                connectionEstablished = false
                readyToSend = false
                delegate?.disconnected()
                disconnect()
                break
            case Stream.Event():
                log.warning("NSStream None.")
                break
            default:
                log.verbose("NSStream Default Case.")
                break
            }
        }
    }
    
    func parseResponse(){
        
        let linesAsStr = linesToStr(self.linesToParse)
        
        switch self.currentQuery {
            
        case .Q_ATD, .Q_ATE0, .Q_ATH0, .Q_ATH1, .Q_ATSPC, .Q_ATSPB, .Q_ATSPA,
             .Q_ATSP9, .Q_ATSP8, .Q_ATSP7, .Q_ATSP6, .Q_ATSP5, .Q_ATSP4, .Q_ATSP3,
             .Q_ATSP2, .Q_ATSP1, .Q_ATSP0:
            if (linesAsStr.contains("OK")){
                parserResponse = (true,[])
            }else {
                parserResponse = (false, [])
            }
        case .Q_ATZ:
            parserResponse = (true, []) // TODO
        case .Q_ATDPN:
            parserResponse = (true, []) // TODO
        case .Q_0100:
            
            if linesAsStr.contains("41"){
                parserResponse = (true,[])
            }else {
                parserResponse = (false, [])
            }
        case .Q_0101:
            numberOfDTCs = parser.parse_0101(linesToParse, obdProtocol: obdProtocol)
        case .Q_03:
            parserResponse = parser.parseDTCs(self.numberOfDTCs, linesToParse: linesToParse, obdProtocol: self.obdProtocol)
        case .Q_0902:
            parserResponse = (false, [])
        case .Q_07:
            parserResponse = (false, [])
        default:
            parserResponse = (false, [])
        }
    }
    
    ////////////////////////////////////////////////////////
    // MARK: EVALUATE STREAM RESPONSE
    ////////////////////////////////////////////////////////
    
    fileprivate func evaluateResponse(){
        
        if setupInProgress {
            
            if (setupStatus == .send_ATD      ||
                setupStatus == .send_ATZ      ||
                setupStatus == .send_ATE0     ||
                setupStatus == .send_ATH0_1   ||
                setupStatus == .send_ATH1_1   ||
                setupStatus == .send_ATDPN    ||
                setupStatus == .send_ATH1_2   ||
                setupStatus == .send_ATH0_2   ){
                
                if (parserResponse.0){
                    if(setupStatus == .send_ATH0_2 ){
                        setupStatus = .finished
                    }else{
                        setupStatus = setupStatus.next()
                    }
                }else {
                    setupStatus = .none
                    log.error("Error")
                    return
                }
                
            }else if (setupStatus == .send_ATSPC){setupStatus = setupStatus.next();obdProtocol = .PC}
            else if  (setupStatus == .send_ATSPB){setupStatus = setupStatus.next();obdProtocol = .PB}
            else if  (setupStatus == .send_ATSPA){setupStatus = setupStatus.next();obdProtocol = .PA}
            else if  (setupStatus == .send_ATSP9){setupStatus = setupStatus.next();obdProtocol = .P9}
            else if  (setupStatus == .send_ATSP8){setupStatus = setupStatus.next();obdProtocol = .P8}
            else if  (setupStatus == .send_ATSP7){setupStatus = setupStatus.next();obdProtocol = .P7}
            else if  (setupStatus == .send_ATSP6){setupStatus = setupStatus.next();obdProtocol = .P6}
            else if  (setupStatus == .send_ATSP5){setupStatus = setupStatus.next();obdProtocol = .P5}
            else if  (setupStatus == .send_ATSP4){setupStatus = setupStatus.next();obdProtocol = .P4}
            else if  (setupStatus == .send_ATSP3){setupStatus = setupStatus.next();obdProtocol = .P3}
            else if  (setupStatus == .send_ATSP2){setupStatus = setupStatus.next();obdProtocol = .P2}
            else if  (setupStatus == .send_ATSP1){setupStatus = setupStatus.next();obdProtocol = .P1}
            else if  (setupStatus == .send_ATSP0){setupStatus = setupStatus.next();obdProtocol = .P0}
            
            //Test selected protocol by sending 0100  two times
            else if(setupStatus == .test_SELECTED_PROTOCOL_1 || setupStatus == .test_SELECTED_PROTOCOL_2){
                switch setupStatus {
                    
                case .test_SELECTED_PROTOCOL_1:
                    if parserResponse.0 {
                        setupStatus = .test_SELECTED_PROTOCOL_FINISHED
                    }else {
                        setupStatus = setupStatus.next()
                    }
                case .test_SELECTED_PROTOCOL_2:
                    
                    if parserResponse.0 {
                        
                        setupStatus = .test_SELECTED_PROTOCOL_FINISHED
                        
                    }else if(obdProtocol != .P0){
                        
                        obdProtocol = obdProtocol.nextProtocol()
                        
                        switch obdProtocol {
                        case .PB: setupStatus = .send_ATSPB
                        case .PA: setupStatus = .send_ATSPA
                        case .P9: setupStatus = .send_ATSP9
                        case .P8: setupStatus = .send_ATSP8
                        case .P7: setupStatus = .send_ATSP7
                        case .P6: setupStatus = .send_ATSP6
                        case .P5: setupStatus = .send_ATSP5
                        case .P4: setupStatus = .send_ATSP4
                        case .P3: setupStatus = .send_ATSP3
                        case .P2: setupStatus = .send_ATSP2
                        case .P1: setupStatus = .send_ATSP1
                        case .P0: setupStatus = .send_ATSP0
                        default: break }
                    }else{
                        setupStatus = .none
//                        log.error("Error")
                        return
                    }
                default:
                    break
                }
            }else if(setupStatus == .test_SELECTED_PROTOCOL_FINISHED){
                setupStatus = .send_ATH1_2
            }
            self.currentSetupStepReady = true
        }else if(self.requestingDTCs)
        {
            switch self.getDTCsStatus {
            case .send_0101: // CHECK HOW MANY DTCs are stored in the vehicle
                if(numberOfDTCs != 0){
                    getDTCsStatus = .send_03
                }else {
                    log.error("NO DTCS TO ASK FOR")
                    return
                }
            case .send_03:
                self.currentDTCs = self.parserResponse.1
                if(currentDTCs.count > 0){
                    getDTCsStatus = .finished
                    self.delegate?.DTCsUpdated(self.currentDTCs, dtcs: numberOfDTCs)
                }else {
                    log.error("NO DTCS")
                    getDTCsStatus = .none
                    return
                }
            case .finished:
                break
            case .none:
                break
            }
            self.currentGetDTCsQueryReady = true
        }
    }

    
    ////////////////////////////////////////////////////////
    // MARK: DETERMINE PROTOCOL
    ////////////////////////////////////////////////////////
    
    func setupAdapter(){
        if setupInProgress {
            return
        }
        self.setupTimer = Timer.scheduledTimer(timeInterval: 0.2, target: self, selector: #selector(self.setupTimedQueries), userInfo: nil, repeats: true)
        //Start the setup by sending ATD to the adapter the rest will be done by the timedFunc and the response evaluator
        self.setupInProgress = true
        self.currentQuery = .Q_ATD
        self.setupStatus = .send_ATD
        sendMessage("ATD", logMessage: "ATD")
    }
    
    func setupTimedQueries(){
        
        if(readyToSend && currentSetupStepReady){
            currentSetupStepReady = false
            
            switch (setupStatus) {
            case .send_ATD: self.currentQuery = .Q_ATD; sendMessage("ATD", logMessage: "ATD"); self.delegate?.setupProgress(5)
            case .send_ATZ: self.currentQuery = .Q_ATZ; sendMessage("ATZ", logMessage: "ATZ"); self.delegate?.setupProgress(10)
            case .send_ATE0: self.currentQuery = .Q_ATE0; sendMessage("ATE0", logMessage: "ATE0"); self.delegate?.setupProgress(15)
            case .send_ATH0_1: self.currentQuery = .Q_ATH0; sendMessage("ATH0", logMessage: "ATH0_1"); self.delegate?.setupProgress(20)
            case .send_ATH1_1: self.currentQuery = .Q_ATH1; sendMessage("ATH1", logMessage: "ATH1_1"); self.delegate?.setupProgress(27)
            case .send_ATDPN: self.currentQuery = .Q_ATDPN; sendMessage("ATDPN", logMessage: "ATDPN"); self.delegate?.setupProgress(35)
            case .send_ATSPC: self.currentQuery = .Q_ATSPC; sendMessage("ATSPC", logMessage: "ATSPC"); self.delegate?.setupProgress(40)
            case .send_ATSPB: self.currentQuery = .Q_ATSPB; sendMessage("ATSPB", logMessage: "ATSPB"); self.delegate?.setupProgress(44)
            case .send_ATSPA: self.currentQuery = .Q_ATSPA; sendMessage("ATSPA", logMessage: "ATSPA"); self.delegate?.setupProgress(47)
            case .send_ATSP9: self.currentQuery = .Q_ATSP9; sendMessage("ATSP9", logMessage: "ATSP9"); self.delegate?.setupProgress(51)
            case .send_ATSP8: self.currentQuery = .Q_ATSP8; sendMessage("ATSP8", logMessage: "ATSP8"); self.delegate?.setupProgress(55)
            case .send_ATSP7: self.currentQuery = .Q_ATSP7; sendMessage("ATSP7", logMessage: "ATSP7"); self.delegate?.setupProgress(59)
            case .send_ATSP6: self.currentQuery = .Q_ATSP6; sendMessage("ATSP6", logMessage: "ATSP6"); self.delegate?.setupProgress(63)
            case .send_ATSP5: self.currentQuery = .Q_ATSP5; sendMessage("ATSP5", logMessage: "ATSP5"); self.delegate?.setupProgress(67)
            case .send_ATSP4: self.currentQuery = .Q_ATSP4; sendMessage("ATSP4", logMessage: "ATSP4"); self.delegate?.setupProgress(71)
            case .send_ATSP3: self.currentQuery = .Q_ATSP3; sendMessage("ATSP3", logMessage: "ATSP3"); self.delegate?.setupProgress(75)
            case .send_ATSP2: self.currentQuery = .Q_ATSP2; sendMessage("ATSP2", logMessage: "ATSP2"); self.delegate?.setupProgress(79)
            case .send_ATSP1: self.currentQuery = .Q_ATSP1; sendMessage("ATSP1", logMessage: "ATSP1"); self.delegate?.setupProgress(83)
            case .send_ATSP0: self.currentQuery = .Q_ATSP0; sendMessage("ATSP0", logMessage: "ATSP0"); self.delegate?.setupProgress(87)
            case .send_ATH1_2: self.currentQuery = .Q_ATH1; sendMessage("ATH1", logMessage: "ATH1_2"); self.delegate?.setupProgress(90)
            case .send_ATH0_2: self.currentQuery = .Q_ATH0; sendMessage("ATH0", logMessage: "ATH0_2"); self.delegate?.setupProgress(95)
            case .test_SELECTED_PROTOCOL_1: self.currentQuery = .Q_0100; sendMessage("0100", logMessage: "0100") //Progress stays the same
            case .test_SELECTED_PROTOCOL_2: self.currentQuery = .Q_0100; sendMessage("0100", logMessage: "0100") //Progress stays the same
            case .test_SELECTED_PROTOCOL_FINISHED: self.setupStatus = .send_ATH1_2; self.currentSetupStepReady = true; self.delegate?.setupProgress(96)
            case .finished:
                self.setupInProgress = false
                self.setupTimer!.invalidate()
                self.delegate?.setupProgress(100)
                log.info("The protocol is \(self.obdProtocol.rawValue)")
            case .none:
                break
            }
        }
    }
    
    ////////////////////////////////////////////////////////
    // MARK: GET DTCS LOGIC
    ////////////////////////////////////////////////////////
    
    func requestDTCs(){
        if requestingDTCs {
            return
        }
        
        self.getDTCsTimer = Timer.scheduledTimer(timeInterval: 0.2, target: self, selector: #selector(self.requestDTCsTimedFunc), userInfo: nil, repeats: true)
        //Start the setup by sending ATD to the adapter the rest will be done by the timedFunc and the response evaluator
        self.requestingDTCs = true
        self.currentQuery = .Q_0101
        self.getDTCsStatus = .send_0101
        sendMessage("0101", logMessage: "0101")
    }
    
    func requestDTCsTimedFunc(){
        
        if(readyToSend && currentGetDTCsQueryReady){
            currentGetDTCsQueryReady = false
            
            switch (getDTCsStatus) {
            case .send_0101: self.currentQuery = .Q_0101; sendMessage("0101", logMessage: "0101")
            case .send_03: self.currentQuery = .Q_03; sendMessage("03", logMessage: "0101")
            case .finished: self.currentQuery = .NONE
            self.requestingDTCs = false
                //Kill the timer if the protocol has been determined
                self.getDTCsTimer!.invalidate()
            case .none:
                break
            }
        }
    }
    
    
    ////////////////////////////////////////////////////////
    // MARK: FUNCTION TO SEND MESSAGE TO ADAPTER
    ////////////////////////////////////////////////////////
    
    fileprivate func sendMessage(_ message: String, logMessage: String = "Sending message."){
        
        let message = "\(message)\r"
        let data = message.data(using: String.Encoding.ascii)
        
        if let connection = connection, let data = data {
            if (connectionEstablished && self.readyToSend){
                log.info("\(logMessage). Message (ASCII): \(data)")
                connection.outputStream!.write((data as NSData).bytes.bindMemory(to: UInt8.self, capacity: data.count), maxLength: data.count)
                return
            }else {
                log.error("Cannot send message: \(message)\nStreamManager.connectionEstablished: \(self.connectionEstablished) \nStreamManager.readyToSend: \(self.readyToSend)")
                return
            }
        }else {
            log.error("Connection is nil.")
            return
        }
    }
    
}
