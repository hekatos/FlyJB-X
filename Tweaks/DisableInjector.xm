#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "../Headers/DisableInjector.h"
#include <sys/syscall.h>
#include <spawn.h>
#import "../Headers/FJPattern.h"

@interface RBSProcessIdentity : NSObject
@property(readonly, copy, nonatomic) NSString *embeddedApplicationIdentifier;
@end

@interface FBProcessExecutionContext : NSObject
@property (nonatomic,copy) NSDictionary* environment;
@property (nonatomic,copy) RBSProcessIdentity* identity;
@end

@interface FBProcessManager : NSObject
@property (assign,nonatomic) int pid;
@end

@interface DisableInjector : NSObject
+(void)cynject:(NSString *)arg1;
@end

@implementation DisableInjector
+(void)cynject:(NSString *)arg1 {
	const char *pidForApp = [arg1 cStringUsingEncoding:NSUTF8StringEncoding];
	pid_t pid;
	int status;
	const char *argv[] = {"cynject", pidForApp, "/Library/Frameworks/FJHooker.framework/FJHooker", NULL};
	posix_spawn(&pid, "/usr/bin/cynject", NULL, NULL, (char* const*)argv, NULL);
	waitpid(pid, &status, WEXITED);
}
@end

BOOL isSubstitute = ([[NSFileManager defaultManager] fileExistsAtPath:@"/usr/lib/libsubstitute.dylib"] && ![[NSFileManager defaultManager] fileExistsAtPath:@"/usr/lib/substrate"] && ![[NSFileManager defaultManager] fileExistsAtPath:@"/usr/lib/libhooker.dylib"]);
const char *DisableLocation = "/var/tmp/.substitute_disable_loader";
BOOL enableCynject = false;

%group DisableInjector
%hook _SBApplicationLaunchAlertInfo
-(NSString *)bundleID {
	if (isSubstitute && syscall(SYS_access, DisableLocation, F_OK) != -1) {
		//NSLog(@"[test] _SBApplicationLaunchAlertInfo bundleID = %@", orig);
		//NSLog(@"[test] Found DisableLocation.");
		int rmResult = remove(DisableLocation);
		if(rmResult == -1) {
			//NSLog(@"[test] Failed to remove file.");
		}
	}
	return %orig;
}
%end

%hook FBProcessManager
-(void)noteProcess:(id)arg1 didUpdateState:(id)arg2 {
	if(enableCynject) {
		NSString *pid = [NSString stringWithFormat:@"%d", [arg2 pid]];
		[DisableInjector performSelectorOnMainThread:@selector(cynject:) withObject:pid waitUntilDone:YES];
	}
	%orig;
	enableCynject = false;
}

//iOS 13 Higher
- (id)_createProcessWithExecutionContext: (FBProcessExecutionContext*)executionContext {
	NSMutableDictionary *prefs = [[NSMutableDictionary alloc] initWithContentsOfFile:@"/var/mobile/Library/Preferences/kr.xsf1re.flyjb.plist"];
	NSMutableDictionary *prefs_disabler = [[NSMutableDictionary alloc] initWithContentsOfFile:@"/var/mobile/Library/Preferences/kr.xsf1re.flyjb_disabler.plist"];
	NSString *bundleID = executionContext.identity.embeddedApplicationIdentifier;
	BOOL bypassConflictApp = ([prefs[bundleID] boolValue] && [FJPatternX isCrashAppWithSubstitutor:bundleID] && ![prefs_disabler[bundleID] boolValue]);

	if([bundleID isEqualToString:@"com.vivarepublica.cash"]) {
		return %orig;
	}

	if([prefs[@"enabled"] boolValue]) {
		//NSLog(@"[test] FBProcessManager _createProcessWithExecutionContext, bundleIDx = %@", bundleIDx);
		if ([prefs_disabler[bundleID] boolValue] || bypassConflictApp) {
			if(isSubstitute) {
				if(bypassConflictApp)
					enableCynject = true;
				FILE* fp = fopen(DisableLocation, "w");
				if (fp == NULL) {
					//NSLog(@"[test] Failed to write DisableLocation.");
				}
			}
			else {
				NSMutableDictionary* environmentM = [executionContext.environment mutableCopy];
				if(bypassConflictApp)
					[environmentM setObject:@"/Library/Frameworks/FJHooker.framework/FJHooker" forKey:@"DYLD_INSERT_LIBRARIES"];
				[environmentM setObject:@(1) forKey:@"_MSSafeMode"];
				[environmentM setObject:@(1) forKey:@"_SafeMode"];
				executionContext.environment = [environmentM copy];
			}

		}
	}
	return %orig;
}

//iOS 12 Lower
-(id)createApplicationProcessForBundleID: (NSString *)bundleID withExecutionContext: (FBProcessExecutionContext*)executionContext {
	NSMutableDictionary *prefs = [[NSMutableDictionary alloc] initWithContentsOfFile:@"/var/mobile/Library/Preferences/kr.xsf1re.flyjb.plist"];
	NSMutableDictionary *prefs_disabler = [[NSMutableDictionary alloc] initWithContentsOfFile:@"/var/mobile/Library/Preferences/kr.xsf1re.flyjb_disabler.plist"];
	BOOL bypassConflictApp = ([prefs[bundleID] boolValue] && [FJPatternX isCrashAppWithSubstitutor:bundleID] && ![prefs_disabler[bundleID] boolValue]);

	if([bundleID isEqualToString:@"com.vivarepublica.cash"]) {
		return %orig;
	}

	if([prefs[@"enabled"] boolValue]) {
		//NSLog(@"[test] FBProcessManager createApplicationProcessForBundleID, bundleIDx = %@", bundleIDx);
		if ([prefs_disabler[bundleID] boolValue] || bypassConflictApp) {
			if(isSubstitute) {
				if(bypassConflictApp)
					enableCynject = true;
				FILE* fp = fopen(DisableLocation, "w");
				if (fp == NULL) {
					//NSLog(@"[test] Failed to write DisableLocation.");
				}
			}
			else {
				NSMutableDictionary* environmentM = [executionContext.environment mutableCopy];
				if(bypassConflictApp)
					[environmentM setObject:@"/Library/Frameworks/FJHooker.framework/FJHooker" forKey:@"DYLD_INSERT_LIBRARIES"];
				[environmentM setObject:@(1) forKey:@"_MSSafeMode"];
				[environmentM setObject:@(1) forKey:@"_SafeMode"];
				executionContext.environment = [environmentM copy];
			}


		}
	}
	return %orig;
}
%end
%end

void loadDisableInjector() {
	%init(DisableInjector);
}
