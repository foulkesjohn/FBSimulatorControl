#import <Foundation/Foundation.h>

@interface XCTestConfigurationHelper : NSObject

- (NSString *)testEnvironmentWithSpecifiedTestConfigurationForBundlePath:(NSString *)xcTestBundlePath;

@end