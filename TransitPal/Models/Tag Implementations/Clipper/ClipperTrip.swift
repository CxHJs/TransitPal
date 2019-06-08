//
//  ClipperTrip.swift
//  TransitPal
//
//  Created by Robert Trencheny on 6/4/19.
//  Copyright © 2019 Robert Trencheny. All rights reserved.
//

import Foundation
import SwiftUI

class ClipperTrip: TransitTrip {
    override init() {}

    init?(_ data: Data) {
        super.init()

        let dataArr = [UInt8](data)

        self.Timestamp = ClipperTag.convertDate(TimeInterval(dataArr.toInt(0xc, 4)))
        self.ExitTimestamp = ClipperTag.convertDate(TimeInterval(dataArr.toInt(0x10, 4)))

        if self.ExitTimestamp == Date(timeIntervalSince1970: -2208988800) {
            self.ExitTimestamp = nil
        }

        self.Fare = dataArr.toInt(0x6, 2)

        let agencyID = dataArr.toInt(0x2, 2)
        let agency = clipperData.Metadata.operators.first { $0.key == agencyID }

        guard let op = agency?.value else { return nil }

        self.Agency = op

        let fromStationID = dataArr.toInt(0x14, 2)

        let toStationID = dataArr.toInt(0x16, 2)

        if let fromStation = ClipperData.getStation(Int(agencyID), fromStationID, false) {
            self.From = fromStation
        } else {
            print("Cant get from station \(MdST.buildStationID(Int(agencyID), fromStationID).hexString)", self)
        }

        if let toStation = ClipperData.getStation(Int(agencyID), toStationID, true) {
            self.To = toStation
        } else {
            print("Cant get to station \(MdST.buildStationID(Int(agencyID), toStationID).hexString)", self)
        }

//        print("Transfer counter", dataArr.toInt(1, 1))
//        print("Transfer agency", dataArr.toInt(2, 2).hexString)
//        print("Transfers???", dataArr.toInt(4, 2).hexString)
//        print("Subscription", dataArr.toInt(8, 2).hexString)

        self.Route = dataArr.toInt(0x1c, 2)
        self.VehicleNumber = dataArr.toInt(0xa, 2)

        self.Mode = TransportType(dataArr.toInt(0x1e, 2), agencyID, self.Agency.defaultTransport)
    }
}

fileprivate extension TransportType {
    init(_ code: Int, _ agencyID: Int, _ fallback: TransportType) {
        switch code {
        case 0x62:
            if let agency = ClipperData.ClipperAgency(rawValue: agencyID) {
                switch agency {
                case .SanFranciscoBayFerry, .GoldenGateFerry:
                    self = .ferry
                    return
                case .Caltrain:
                    self = .train
                    return
                default:
                    self = .tram
                    return
                }
            }
            self = .tram
            return
        case 0x6f:
            self = .metro
            return
        case 0x61, 0x75:
            self = .bus
            return
        default:
            self = fallback
            return
        }
    }
}
