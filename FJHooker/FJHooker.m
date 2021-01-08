#import "FJHooker.h"
#import <objc/runtime.h>
#import <CaptainHook/CaptainHook.h>
#import "../Headers/FJPattern.h"
#include <mach-o/dyld.h>
#import "../Headers/dobby.h"
#include <dlfcn.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <netdb.h>
#include <mach/mach.h>
#include <mach-o/dyld_images.h>

CHDeclareClass(UIApplication);
CHMethod1(BOOL, UIApplication, canOpenURL, NSURL *, url)
{
  if([[FJPattern sharedInstance] isURLRestricted:url]) {
    // NSLog(@"[FJHooker] Blocked canOpenURL %@", url);
    return NO;
  }
  //NSLog(@"[FJHooker] Detected canOpenURL %@", url);
  return CHSuper(1, UIApplication, canOpenURL, url);
}

CHDeclareClass(NSFileManager);
CHMethod1(BOOL, NSFileManager, fileExistsAtPath, NSString *, path)
{
    if([[FJPattern sharedInstance] isPathRestricted:path]) {
      //NSLog(@"[FJHooker] Blocked fileExistsAtPath %@", path);
      return NO;
    }
    //NSLog(@"[FJHooker] Detected fileExistsAtPath %@", path);
    return CHSuper(1, NSFileManager, fileExistsAtPath, path);
}

CHMethod2(BOOL, NSFileManager, fileExistsAtPath, NSString *, path, isDirectory, BOOL *, isDirectory)
{
    if([[FJPattern sharedInstance] isPathRestricted:path]) {
      // NSLog(@"[FJHooker] Blocked fileExistsAtPath isDirectory %@", path);
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
		if([[FJPattern sharedInstance] isPathRestricted:path])
		{
//      NSLog(@"[FJHooker] fopen block: %@", path);
			errno = ENOENT;
			return NULL;
		}
	}
	return orig_fopen(pathname, mode);
}

static int (*orig_access) (const char *pathname, int mode);
static int hook_access(const char* pathname, int mode) {
	if(pathname) {
		NSString *path = [[NSFileManager defaultManager] stringWithFileSystemRepresentation:pathname length:strlen(pathname)];
		if([[FJPattern sharedInstance] isPathRestricted:path])
		{
      //NSLog(@"[FJHooker] access blocked: %@",path);
			errno = ENOENT;
			return -1;
		}
	}
  //NSLog(@"[FJHooker] access detected: %s",pathname);
	return orig_access(pathname, mode);
}

static char* (*orig_getenv)(const char* name);
static char* hook_getenv(const char* name) {
	if(name) {
		NSString *env = [NSString stringWithUTF8String:name];

		if([env isEqualToString:@"DYLD_INSERT_LIBRARIES"]
		   || [env isEqualToString:@"_MSSafeMode"]
		   || [env isEqualToString:@"_SafeMode"]) {
			return NULL;
		}
	}
	return orig_getenv(name);
}

// uint32_t dyldCount = 0;
// char **dyldNames = 0;
// struct mach_header **dyldHeaders = 0;
// void syncDyldArray() {
// 	uint32_t count = _dyld_image_count();
// 	uint32_t counter = 0;
// 	//NSLog(@"[FlyJB] There are %u images", count);
// 	dyldNames = (char **) calloc(count, sizeof(char **));
// 	dyldHeaders = (struct mach_header **) calloc(count, sizeof(struct mach_header **));
// 	for (int i = 0; i < count; i++) {
// 		const char *charName = _dyld_get_image_name(i);
// 		if (!charName) {
// 			continue;
// 		}
// 		NSString *name = [NSString stringWithUTF8String: charName];
// 		if (!name) {
// 			continue;
// 		}
// 		NSString *lower = [name lowercaseString];
// 		if ([lower rangeOfString:@"substrate"].location != NSNotFound ||
// 		    [lower rangeOfString:@"substitute"].location != NSNotFound ||
// 		    [lower rangeOfString:@"substitrate"].location != NSNotFound ||
// 		    [lower rangeOfString:@"cephei"].location != NSNotFound ||
// 		    [lower rangeOfString:@"rocketbootstrap"].location != NSNotFound ||
// 		    [lower rangeOfString:@"tweakinject"].location != NSNotFound ||
// 		    [lower rangeOfString:@"jailbreak"].location != NSNotFound ||
// 		    [lower rangeOfString:@"cycript"].location != NSNotFound ||
// 		    [lower rangeOfString:@"pspawn"].location != NSNotFound ||
// 		    [lower rangeOfString:@"libcolorpicker"].location != NSNotFound ||
// 		    [lower rangeOfString:@"libcs"].location != NSNotFound ||
// 		    [lower rangeOfString:@"bfdecrypt"].location != NSNotFound ||
// 		    [lower rangeOfString:@"sbinject"].location != NSNotFound ||
// 		    [lower rangeOfString:@"dobby"].location != NSNotFound ||
// 		    [lower rangeOfString:@"libhooker"].location != NSNotFound ||
// 		    [lower rangeOfString:@"snowboard"].location != NSNotFound ||
// 		    [lower rangeOfString:@"libblackjack"].location != NSNotFound ||
// 		    [lower rangeOfString:@"libobjc-trampolines"].location != NSNotFound ||
// 		    [lower rangeOfString:@"cephei"].location != NSNotFound ||
// 		    [lower rangeOfString:@"libmryipc"].location != NSNotFound ||
// 		    [lower rangeOfString:@"libactivator"].location != NSNotFound ||
// 		    [lower rangeOfString:@"alderis"].location != NSNotFound ||
// 		    [lower rangeOfString:@"libcloaky"].location != NSNotFound) {
// 			//NSLog(@"[FlyJB] BYPASSED dyld = %@", name);
// 			continue;
// 		}
// 		uint32_t idx = counter++;
// 		dyldNames[idx] = strdup(charName);
// 		dyldHeaders[idx] = (struct mach_header *) _dyld_get_image_header(i);
// 	}
// 	dyldCount = counter;
// }
//
// static uint32_t (*orig_dyld_image_count);
// static uint32_t hook_dyld_image_count() {
//   return dyldCount;
// }
//
// const char* (*orig_dyld_get_image_name)(uint32_t image_index);
// const char* hook_dyld_get_image_name(uint32_t image_index){
//   return dyldNames[image_index];
// }
//
// struct mach_header* (*orig_dyld_get_image_header)(uint32_t image_index);
// struct mach_header* hook_dyld_get_image_header(uint32_t image_index) {
// 	return dyldHeaders[image_index];
// }

static char* (*orig_strstr)(const char* s1, const char* s2);
static char* hook_strstr(const char* s1, const char* s2) {
  if(strcmp(s2, "/Library/MobileSubstrate/") == 0
      || strcmp(s2, "/Flex.dylib") == 0
      || strcmp(s2, "/introspy.dylib") == 0
      || strcmp(s2, "/MobileSubstrate.dylib") == 0
      || strcmp(s2, "/CydiaSubstrate.framework") == 0
      || strcmp(s2, "/.file") == 0
      || strcmp(s2, "!@#") == 0
      || strcmp(s2, "frida")== 0
      || strcmp(s2, "Frida") == 0
      || strcmp(s2, "ubstrate") == 0)
      return NULL;
  return orig_strstr(s1, s2);
}

kern_return_t (*orig_task_info)(task_name_t target_task, task_flavor_t flavor, task_info_t task_info_out, mach_msg_type_number_t *task_info_outCnt);
kern_return_t hook_task_info(task_name_t target_task, task_flavor_t flavor, task_info_t task_info_out, mach_msg_type_number_t *task_info_outCnt) {
  if (flavor == TASK_DYLD_INFO) {
		kern_return_t ret = orig_task_info(target_task, flavor, task_info_out, task_info_outCnt);
		if (ret == KERN_SUCCESS) {
			struct task_dyld_info *task_info = (struct task_dyld_info *) task_info_out;
			struct dyld_all_image_infos *dyld_info = (struct dyld_all_image_infos *) task_info->all_image_info_addr;
			dyld_info->infoArrayCount = 1;
		}
		return ret;
	}
	return orig_task_info(target_task, flavor, task_info_out, task_info_outCnt);
}

@implementation FJHooker
+(void)load {
    NSLog(@"[FJHooker] Hello, FJHooker!");

    NSMutableDictionary *prefs = [[NSMutableDictionary alloc] initWithContentsOfFile:@"/var/mobile/Library/Preferences/kr.xsf1re.flyjb.plist"];
    BOOL DobbyHook = [prefs[@"enableDobby"] boolValue];

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

    void (*FJHook)(void *symbol, void *replace, void **result) = NULL;
    void *handler = NULL;
    if(DobbyHook) {
      handler = dlopen("/Library/Frameworks/FlyJBDobby.framework/Dobby", RTLD_NOW);
      FJHook = (void (*)(void *, void *, void **))dlsym(handler, "DobbyHook");
    }
    else {
      handler = dlopen("/Library/Frameworks/CydiaSubstrate.framework/CydiaSubstrate", RTLD_NOW);
      FJHook = (void (*)(void *, void *, void **))dlsym(handler, "MSHookFunction");
    }

    FJHook((void *)fopen, (void *)hook_fopen, (void **)&orig_fopen);
    FJHook((void *)access, (void *)hook_access, (void **)&orig_access);
    FJHook((void *)getenv, (void *)hook_getenv, (void **)&orig_getenv);

    NSString* bundleID = [[NSBundle mainBundle] bundleIdentifier];
    if([bundleID isEqualToString:@"com.kbankwith.smartbank"] || [bundleID isEqualToString:@"kr.kbsec.iplustar"] || [bundleID isEqualToString:@"com.Kiwoom.HeroSMobile"]) {
      NSLog(@"[FJHooker] Starting Hook for Stealien Apps!");

      // syncDyldArray();
      // FJHook((void *)_dyld_image_count, (void *)hook_dyld_image_count, (void **)&orig_dyld_image_count);
      // FJHook((void *)_dyld_get_image_name, (void *)hook_dyld_get_image_name, (void **)&orig_dyld_get_image_name);
      // FJHook((void *)_dyld_get_image_header, (void *)hook_dyld_get_image_header, (void **)&orig_dyld_get_image_header);
      FJHook((void *)dlsym(RTLD_DEFAULT, "strstr"), (void *)hook_strstr, (void **)&orig_strstr);
    }

    if([bundleID isEqualToString:@"com.teamblind.blind"]) {
      FJHook((void*)task_info, (void*)hook_task_info, (void**)&orig_task_info);
    }
    dlclose(handler);
  }

+(void)loadNSStringWriteLongHook {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{

    Method originalMethod = class_getInstanceMethod([NSString class], @selector(writeToFile:atomically:encoding:error:));
    IMP originalMethodImp = method_getImplementation(originalMethod);
    class_addMethod([NSString class], @selector(fake__writeToFile:atomically:encoding:error:), originalMethodImp, method_getTypeEncoding(originalMethod));

    Method newMethod = class_getInstanceMethod([self class], @selector(writeToFileHooked:atomically:encoding:error:));
    IMP newMethodImp = method_getImplementation(newMethod);
    class_replaceMethod([NSString class], @selector(writeToFile:atomically:encoding:error:), newMethodImp, method_getTypeEncoding(newMethod));
    });
}

-(BOOL)writeToFileHooked:(NSString*)path atomically:(BOOL)useAuxiliaryFile encoding:(NSStringEncoding)enc error:(NSError * _Nullable *)error {

  if([[FJPattern sharedInstance] isSandBoxPathRestricted:path]) {
//    NSLog(@"[FJHooker] Blocked writeToFile(Long): %@", path);
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
