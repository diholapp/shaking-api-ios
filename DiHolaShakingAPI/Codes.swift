/*
 * Copyright © 2019 DiHola S.L. All rights reserved.
 */

import Foundation

@objc public enum ShakingCode : Int {
    case LOCATION_PERMISSION_ERROR
    case LOCATION_DISABLED
    case AUTHENTICATION_ERROR
    case API_KEY_EXPIRED
    case SERVER_ERROR
    case SENSOR_ERROR
}
