#import <Foundation/Foundation.h>
#include "UnityFramework/UnityFramework-Swift.h"

extern "C" {
static char* jsonString = NULL;
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
        NSString *jsonNSString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
        const char *utf8String = [jsonNSString UTF8String];
        jsonString = strdup(utf8String); // Duplicate the string to ensure it is not freed
        return jsonString;
    }
}
}