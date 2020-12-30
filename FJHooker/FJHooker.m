#import "FJHooker.h"
#import "fishhook/fishhook.h"
#import <objc/runtime.h>
#import <CaptainHook/CaptainHook.h>
#import "FJHPattern.h"

CHDeclareClass(UIApplication);
CHMethod1(BOOL, UIApplication, canOpenURL, NSURL *, url)
{
  if([FJHPattern isURLRestricted:url]) {
    NSLog(@"[FJHooker] Blocked canOpenURL %@", url);
    return NO;
  }
  //NSLog(@"[FJHooker] Detected canOpenURL %@", url);
  return CHSuper(1, UIApplication, canOpenURL, url);
}

CHDeclareClass(NSFileManager);
CHMethod1(BOOL, NSFileManager, fileExistsAtPath, NSString *, path)
{
    if([FJHPattern isPathRestricted:path]) {
      NSLog(@"[FJHooker] Blocked fileExistsAtPath %@", path);
      return NO;
    }
    //NSLog(@"[FJHooker] Detected fileExistsAtPath %@", path);
    return CHSuper(1, NSFileManager, fileExistsAtPath, path);
}

CHMethod2(BOOL, NSFileManager, fileExistsAtPath, NSString *, path, isDirectory, BOOL *, isDirectory)
{
    if([FJHPattern isPathRestricted:path]) {
      NSLog(@"[FJHooker] Blocked fileExistsAtPath isDirectory %@", path);
      return NO;
    }

    //NSLog(@"[FJHooker] Detected fileExistsAtPath isDirectory %@", path);
    return CHSuper(2, NSFileManager, fileExistsAtPath, path, isDirectory, isDirectory);
}

CHDeclareClass(AMSLFairPlayInspector);
CHClassMethod1(id, AMSLFairPlayInspector, unarchive, id, arg1)
{
  NSMutableDictionary *dict = [NSMutableDictionary dictionary];
	NSData *object_nsdata = [@"AhnLab.bypass" dataUsingEncoding:NSUTF8StringEncoding];
	[dict setObject:object_nsdata forKey:@"kConfirm"];
	[dict setObject:object_nsdata forKey:@"kConfirmValidation"];
	[dict setObject:object_nsdata forKey:@"8D9188AA-36C3-428E-BE4C-134EF1EBF648"];
	[dict setObject:object_nsdata forKey:@"95BA52F0-0A20-4728-89C1-18B5E69ECE04"];
	return dict;
  // return CHSuper(1, AMSLFairPlayInspector, unarchive, arg1);
}

CHClassMethod2(id, AMSLFairPlayInspector, hmacWithSierraEchoCharlieRomeoEchoTango, id, arg1, andData, id, arg2)
{
  NSData *object_nsdata = [@"AhnLab.bypass" dataUsingEncoding:NSUTF8StringEncoding];
	return object_nsdata;
  // return CHSuper(2, AMSLFairPlayInspector, hmacWithSierraEchoCharlieRomeoEchoTango, arg1, andData, arg2);
}

CHMethod1(id, AMSLFairPlayInspector, fairPlayWithResponseAck, id, arg1)
{
  return nil;
  // return CHSuper(1, AMSLFairPlayInspector, fairPlayWithResponseAck, arg1);
}

CHDeclareClass(AppJailBrokenChecker);
CHClassMethod0(int, AppJailBrokenChecker, isAppJailbroken)
{
  return 0;
}

// CHDeclareClass(CTCarrier);
// CHMethod0(id, CTCarrier, mobileNetworkCode)
// {
//   return @"06";
// }
//
// CHMethod0(id, CTCarrier, mobileCountryCode)
// {
//   return @"450";
// }

CHDeclareClass(mVaccine);
CHClassMethod0(BOOL, mVaccine, isJailBreak)
{
  return false;
}

CHClassMethod0(BOOL, mVaccine, mvc)
{
  return false;
}

static FILE *(*orig_fopen) (const char * pathname, const char * mode);
FILE* hook_fopen(const char *pathname, const char *mode) {
  if(pathname) {
		NSString *path = [[NSFileManager defaultManager] stringWithFileSystemRepresentation:pathname length:strlen(pathname)];
		if([FJHPattern isPathRestricted:path])
		{
      NSLog(@"[FJHooker] fopen block: %@", path);
			errno = ENOENT;
			return NULL;
		}
	}
	return orig_fopen(pathname, mode);
}

@implementation FJHooker
+(void)load {
    NSLog(@"[FJHooker] Hello, FJHooker!");

    CHLoadLateClass(UIApplication);
    CHHook1(UIApplication, canOpenURL);

    CHLoadClass(NSFileManager);
    CHHook1(NSFileManager, fileExistsAtPath);
    CHHook2(NSFileManager, fileExistsAtPath, isDirectory);

    [self loadNSStringWriteLongHook];


    CHLoadLateClass(AMSLFairPlayInspector);
    CHHook1(AMSLFairPlayInspector, unarchive);
    CHHook2(AMSLFairPlayInspector, hmacWithSierraEchoCharlieRomeoEchoTango, andData);
    CHHook1(AMSLFairPlayInspector, fairPlayWithResponseAck);

    CHLoadLateClass(AppJailBrokenChecker);
    CHHook0(AppJailBrokenChecker, isAppJailbroken);

    CHLoadLateClass(mVaccine);
    CHHook0(mVaccine, isJailBreak);
    CHHook0(mVaccine, mvc);

    // CHLoadLateClass(CTCarrier);
    // CHHook0(CTCarrier, mobileCountryCode);
    // CHHook0(CTCarrier, mobileNetworkCode);

    rebind_symbols((struct rebinding[1]){{"fopen", (void *)hook_fopen, (void **)&orig_fopen}}, 1);
  }

+(void)loadNSStringWriteLongHook {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{

    // FJHooker fake__fileExistsAtPath <- NSFileManager fileExistsAtPath
    Method originalMethod = class_getInstanceMethod([NSString class], @selector(writeToFile:atomically:encoding:error:));
    IMP originalMethodImp = method_getImplementation(originalMethod);
    class_addMethod([NSString class], @selector(fake__writeToFile:atomically:encoding:error:), originalMethodImp, method_getTypeEncoding(originalMethod));

    //FJHooker fileExistsAtPathHooked <-> fileExistsAtPath
    Method newMethod = class_getInstanceMethod([self class], @selector(writeToFileHooked:atomically:encoding:error:));
    IMP newMethodImp = method_getImplementation(newMethod);
    class_replaceMethod([NSString class], @selector(writeToFile:atomically:encoding:error:), newMethodImp, method_getTypeEncoding(newMethod));
    });
}

-(BOOL)writeToFileHooked:(NSString*)path atomically:(BOOL)useAuxiliaryFile encoding:(NSStringEncoding)enc error:(NSError * _Nullable *)error {

  if([FJHPattern isSandBoxPathRestricted:path]) {
    NSLog(@"[FJHooker] Blocked writeToFile(Long): %@", path);
    return [self fake__writeToFile:nil atomically:useAuxiliaryFile encoding:enc error:error];
  }
  //NSLog(@"[FJHooker] Detected writeToFile(Long): %@", path);
  return [self fake__writeToFile:path atomically:useAuxiliaryFile encoding:enc error:error];
}

- (BOOL)fake__writeToFile:(NSString*)path atomically:(BOOL)useAuxiliaryFile encoding:(NSStringEncoding)enc error:(NSError * _Nullable *)error
{
  //NEVER RUN THIS CODE!!!
  NSLog(@"[FJHooker] WTF???");
  return NO;
}

@end


// int (*orig_access)(const char *path, int mode);
// static int hook_access(const char *path, int mode) {
//     NSLog(@"[FJHooker] hook_access: %s", path);
//     return orig_access(path, mode);
// }

// @implementation FJHooker
// +(void)load {
//     NSLog(@"[FJHooker] Hello, FJHooker!");
//
//     NSString *bundleID = [[NSBundle mainBundle] bundleIdentifier];
//     NSLog(@"[FJHooker] Conflict app is %@!", bundleID);
//
//     // rebind_symbols((struct rebinding[1]){{"access", (void *)hook_access, (void **)&orig_access}}, 1);
//     static dispatch_once_t onceToken;
//     dispatch_once(&onceToken, ^{
//
//       // FJHooker fake__fileExistsAtPath <- NSFileManager fileExistsAtPath
//       Method originalMethod = class_getInstanceMethod([NSFileManager class], @selector(fileExistsAtPath:));
//       IMP originalMethodImp = method_getImplementation(originalMethod);
//       class_addMethod([NSFileManager class], @selector(fake__fileExistsAtPath:), originalMethodImp, method_getTypeEncoding(originalMethod));
//
//       //FJHooker fileExistsAtPathHooked <-> fileExistsAtPath
//       Method newMethod = class_getInstanceMethod([self class], @selector(fileExistsAtPathHooked:));
//       IMP newMethodImp = method_getImplementation(newMethod);
//       class_replaceMethod([NSFileManager class], @selector(fileExistsAtPath:), newMethodImp, method_getTypeEncoding(newMethod));
//     });
// }
//
// -(BOOL)fileExistsAtPathHooked:(NSString *)path {
//
//   BOOL orig = [self fake__fileExistsAtPath:path];
//   NSLog(@"[FJHooker] WTF1: %@, orig: %d", path, orig);
//   return orig;
// }
//
// - (BOOL)fake__fileExistsAtPath:(NSString *)path
// {
//   NSLog(@"[FJHooker] WTF2");
//   return YES;
// }
//
// @end
