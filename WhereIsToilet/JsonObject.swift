//
//  JsonObject.swift
//  WhereIsToilet
//
//  Created by 송시온 on 07/08/2019.
//  Copyright © 2019 송시온. All rights reserved.
//

import Foundation

struct ToiletInfo: Codable {
    var type: String
    var name: String
    var unisex: String
    var man_type1_cnt: String
    var man_type2_cnt: String
    var disabledman_type1_cnt: String
    var disabledman_type2_cnt: String
    var boy_type1_cnt: String
    var boy_type2_cnt: String
    var woman_type1_cnt: String
    var disabledwoman_type1_cnt: String
    var girl_type1_cnt: String
    var owner: String
    var tel: String
    var open_time: String
    var install_date: String?
    var lng: String
    var lat: String
    var reg_date: String
    var dist: Float
}
