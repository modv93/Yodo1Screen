// SystemMonitorBridge.m

#import <Foundation/Foundation.h>
#import "Unity-iPhone-Bridging-Header.h"

void _startTracking() {
    [[SystemMonitor shared] startTracking];
}

const char* _stopTracking() {
    NSDictionary *result = [[SystemMonitor shared] stopTracking];
    NSError *error;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:result options:NSJSONWritingPrettyPrinted error:&error];

    if (!jsonData) {
        NSLog(@"Got an error: %@", error);
        return nil;
    } else {
        NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
        return [jsonString UTF8String];
    }
}
