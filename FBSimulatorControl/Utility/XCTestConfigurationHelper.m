#import "XCTestConfigurationHelper.h"
#import "XCTestConfiguration.h"

@implementation XCTestConfigurationHelper

static NSString *__tempDirectoryForAction = nil;

NSString *MakeTemporaryDirectory(NSString *nameTemplate)
{
  NSMutableData *template = [[[NSTemporaryDirectory() stringByAppendingPathComponent:nameTemplate]
                              dataUsingEncoding:NSUTF8StringEncoding] mutableCopy];
  [template appendBytes:"\0" length:1];
  
  if (!mkdtemp(template.mutableBytes)) {
    NSLog(@"Failed to create temporary directory: %s", strerror(errno));
    abort();
  }
  
  return [NSString stringWithUTF8String:template.bytes];
}

NSString *TemporaryDirectoryForAction()
{
  if (__tempDirectoryForAction == nil) {
    NSString *nameTemplate = [NSString stringWithFormat:@"FBSimulatorControl_temp_%d", [[NSProcessInfo processInfo] processIdentifier]];
    __tempDirectoryForAction = MakeTemporaryDirectory(nameTemplate);
  }
  
  return __tempDirectoryForAction;
}

NSString *MakeTempFileInDirectoryWithPrefix(NSString *directory, NSString *prefix)
{
  const char *template = [[directory stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.XXXXXXX", prefix]] UTF8String];
  
  char tempPath[PATH_MAX] = {0};
  strcpy(tempPath, template);
  
  int handle = mkstemp(tempPath);
  NSCAssert(handle != -1, @"Failed to make temporary file name for template %s, error: %d", template, handle);
  close(handle);
  
  return @(tempPath);
}

NSString *MakeTempFileWithPrefix(NSString *prefix)
{
  return MakeTempFileInDirectoryWithPrefix(TemporaryDirectoryForAction(), prefix);
}

- (NSString *)testEnvironmentWithSpecifiedTestConfigurationForBundlePath:(NSString *)xcTestBundlePath
{
  NSArray *testCasesToSkip = nil;// [self testCasesToSkip];
  
  Class XCTestConfigurationClass = NSClassFromString(@"XCTestConfiguration");
  NSAssert(XCTestConfigurationClass, @"XCTestConfiguration isn't available");
  
  XCTestConfiguration *configuration = [[XCTestConfigurationClass alloc] init];
  [configuration setProductModuleName:@"TableSearchTests"];
  [configuration setTestBundleURL:[NSURL fileURLWithPath:xcTestBundlePath]];
  [configuration setTestsToSkip:[NSSet setWithArray:testCasesToSkip]];
  [configuration setReportResultsToIDE:NO];

  NSString *XCTestConfigurationFilename = [NSString stringWithFormat:@"%@-%@", @"TableSearchTests", [configuration.sessionIdentifier UUIDString]];
  NSString *XCTestConfigurationFilePath = [MakeTempFileWithPrefix(XCTestConfigurationFilename) stringByAppendingPathExtension:@"xctestconfiguration"];
  if ([[NSFileManager defaultManager] fileExistsAtPath:XCTestConfigurationFilePath]) {
    [[NSFileManager defaultManager] removeItemAtPath:XCTestConfigurationFilePath error:nil];
  }
  if (![NSKeyedArchiver archiveRootObject:configuration toFile:XCTestConfigurationFilePath]) {
    NSAssert(NO, @"Couldn't archive XCTestConfiguration to file at path %@", XCTestConfigurationFilePath);
  }
  
  return XCTestConfigurationFilePath;
}

@end