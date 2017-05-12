//
//  Weex-BluetoothModule.h
//  testWeex
//
//  Created by 李 行 on 08/05/2017.
//  Copyright © 2017 lixing123.com. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <WeexSDK/WeexSDK.h>

#define RESULT_STRING @"result"
#define RESULT_STRING_SUCCEED @"succeed"
#define RESULT_STRING_FAILED @"fail"

#define ERROR_CODE_STRING @"errCode"
#define ERROR_CODE_SUCCEED @"0"


#define DEBUG_MODE

#ifdef DEBUG_MODE
#define LXLog(fmt, ...) NSLog((fmt), ##__VA_ARGS__)
#else
#define LXLog(...)
#endif

@interface Weex_BluetoothModule : NSObject<WXModuleProtocol>

@end
