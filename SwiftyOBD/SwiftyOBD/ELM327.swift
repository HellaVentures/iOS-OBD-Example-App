//
//  Enums.swift
//  SwiftyOBD-Example
//
//  Created by Daniel Montano on 06.10.16.
//  Copyright © 2016 Hella Ventures Berlin. All rights reserved.
//

import Foundation

enum ELM327 {
    
    enum RESPONSE {
    
        enum ERROR: String {
            
            case QUESTION_MARK = "?",
            ACT_ALERT = "ACT ALERT",
            BUFFER_FULL = "BUFFER FULL",
            BUS_BUSSY = "BUS BUSSY",
            BUS_ERROR = "BUS ERROR",
            CAN_ERROR = "CAN ERROR",
            DATA_ERROR = "DATA ERROR",
            ERRxx = "ERR",
            FB_ERROR = "FB ERROR",
            LP_ALERT = "LP ALERT",
            LV_RESET = "LV RESET",
            NO_DATA = "NO DATA",
            RX_ERROR = "RX ERROR",
            STOPPED = "STOPPED",
            UNABLE_TO_CONNECT = "UNABLE TO CONNECT"
            
            static let asArray: [ERROR] = [QUESTION_MARK, ACT_ALERT, BUFFER_FULL, BUS_BUSSY,
                                           BUS_ERROR, CAN_ERROR, DATA_ERROR, ERRxx, FB_ERROR,
                                           LP_ALERT, LV_RESET, NO_DATA, RX_ERROR,STOPPED,
                                           UNABLE_TO_CONNECT]
        }
    }
    
    enum QUERY: String {
        case
        Q_ATD = "ATD",
        Q_ATZ = "ATZ",
        Q_ATE0 = "ATE0",
        Q_ATH0 = "ATH",
        Q_ATH1 = "ATH1",
        Q_ATDPN = "ATDPN",
        Q_ATSPC = "ATSPC",
        Q_ATSPB = "ATSPB",
        Q_ATSPA = "ATSPA",
        Q_ATSP9 = "ATSP9",
        Q_ATSP8 = "ATSP8",
        Q_ATSP7 = "ATSP7",
        Q_ATSP6 = "ATSP6",
        Q_ATSP5 = "ATSP5",
        Q_ATSP4 = "ATSP4",
        Q_ATSP3 = "ATSP3",
        Q_ATSP2 = "ATSP2",
        Q_ATSP1 = "ATSP1",
        Q_ATSP0 = "ATSP0",
        Q_0100 = "0100",
        Q_0101 = "0101",
        Q_0902 = "0902",
        Q_03 = "03",
        Q_07 = "07",
        NONE = "None"
        
        static let asArray: [QUERY] = [Q_ATD, Q_ATZ, Q_ATE0,Q_ATH0,
                                       Q_ATH1, Q_ATDPN, Q_ATSPC,Q_ATSPB,
                                       Q_ATSPA,Q_ATSP9, Q_ATSP8,Q_ATSP7,
                                       Q_ATSP6,Q_ATSP5, Q_ATSP4,Q_ATSP3,
                                       Q_ATSP2,Q_ATSP1, Q_ATSP0,Q_0100,
                                       Q_0101 ,Q_0902, Q_03, Q_07, NONE]
        
        enum SETUP_STEP{
            
            case
            send_ATD,
            send_ATZ,
            send_ATE0,
            send_ATH0_1,
            send_ATH1_1,
            send_ATDPN,
            send_ATSPC,
            send_ATSPB,
            send_ATSPA,
            send_ATSP9,
            send_ATSP8,
            send_ATSP7,
            send_ATSP6,
            send_ATSP5,
            send_ATSP4,
            send_ATSP3,
            send_ATSP2,
            send_ATSP1,
            send_ATSP0,
            send_ATH1_2,
            send_ATH0_2,
            test_SELECTED_PROTOCOL_1,
            test_SELECTED_PROTOCOL_2,
            test_SELECTED_PROTOCOL_FINISHED,
            finished,
            none
            
            func next() -> SETUP_STEP{
                switch (self) {
                    
                case .send_ATD: return .send_ATZ
                case .send_ATZ: return .send_ATE0
                case .send_ATE0: return .send_ATH0_1
                case .send_ATH0_1: return .send_ATH1_1
                case .send_ATH1_1: return .send_ATDPN
                case .send_ATDPN: return .send_ATSPC
                case .send_ATSPC, .send_ATSPB, .send_ATSPA, .send_ATSP9, .send_ATSP8, .send_ATSP7,
                     .send_ATSP6, .send_ATSP5, .send_ATSP4, .send_ATSP3, .send_ATSP2, .send_ATSP1, .send_ATSP0:
                    return .test_SELECTED_PROTOCOL_1
                case .send_ATH1_2: return .send_ATH0_2
                case .send_ATH0_2: return .finished
                case .finished: return .none
                case .test_SELECTED_PROTOCOL_1: return .test_SELECTED_PROTOCOL_2
                case .test_SELECTED_PROTOCOL_2: return .test_SELECTED_PROTOCOL_FINISHED
                case .test_SELECTED_PROTOCOL_FINISHED: return .test_SELECTED_PROTOCOL_FINISHED
                case .none: return .none
                }
            }
        }//END SETUP_STEP
        
        enum GET_DTCS_STEP{
            
            //Setup goes in this order
            case
            send_0101,
            send_03,
            finished,
            none
            
            func next() -> GET_DTCS_STEP{
                switch (self) {
                    
                case .send_0101: return .send_03
                case .send_03: return .finished
                case .finished: return .none
                case .none: return .none
                }
            }
        }//END GET_DTCS_STEP
    }//END QUERY
    
    enum PROTOCOL: String {
        
        case
        P0 = "0: Automatic",
        P1 = "1: SAE J1850 PWM (41.6 kbaud)",
        P2 = "2: SAE J1850 VPW (10.4 kbaud)",
        P3 = "3: ISO 9141-2 (5 baud init, 10.4 kbaud)",
        P4 = "4: ISO 14230-4 KWP (5 baud init, 10.4 kbaud)",
        P5 = "5: ISO 14230-4 KWP (fast init, 10.4 kbaud)",
        P6 = "6: ISO 15765-4 CAN (11 bit ID,500 Kbaud)",
        P7 = "7: ISO 15765-4 CAN (29 bit ID,500 Kbaud)",
        P8 = "8: ISO 15765-4 CAN (11 bit ID,250 Kbaud)",
        P9 = "9: ISO 15765-4 CAN (29 bit ID,250 Kbaud)",
        PA = "A: SAE J1939 CAN (11* bit ID, 250* kbaud)",
        PB = "B: USER1 CAN (11* bit ID, 125* kbaud)",
        PC = "B: USER1 CAN (11* bit ID, 50* kbaud)",
        NONE = "None"
        
        static let asArray: [PROTOCOL] = [P0, P1, P2, P3, P4, P5, P6, P7, P8, P9, PA, PB, PC, NONE]
        
        func nextProtocol() -> PROTOCOL{
            switch self {
            case .PC:
                return .PB
            case .PB:
                return .PA
            case .PA:
                return .P9
            case .P9:
                return .P8
            case .P8:
                return .P7
            case .P7:
                return .P6
            case .P6:
                return .P5
            case .P5:
                return .P4
            case .P4:
                return .P3
            case .P3:
                return .P2
            case .P2:
                return .P1
            case .P1:
                return .P0
            default:
                return .NONE
            }
        }
    }//END PROTOCOL
}
