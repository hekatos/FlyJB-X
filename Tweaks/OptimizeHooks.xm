#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "../Headers/OptimizeHooks.h"
#include <dlfcn.h>

%group OptimizeHooks
%hookf(void *, dlopen, const char *path, int mode) {
	if (path == NULL) return %orig(path, mode);
	{
		NSString *nspath = @(path);
		if([nspath hasPrefix:@"/Library/MobileSubstrate/DynamicLibraries/"]
		   && [nspath hasSuffix:@".dylib"])
		{
			return NULL;
		}
		return %orig(path, mode);
	}
}
%end

%group OptimizeHooksForSubstrate
%hookf(int, access, const char *path, int mode) {
	if (path) {
		NSString *nspath = [NSString stringWithUTF8String:path];
		if([nspath hasPrefix:@"/Library/MobileSubstrate/DynamicLibraries/"]
		   && [nspath hasSuffix:@".plist"]) {
			NSLog(@"[FlyJB] access blocked: %@", nspath);
			errno = EACCES;
			return -1;
		}
	}
	return %orig(path, mode);
}
%end

void loadOptimizeHooks() {

	BOOL isLibHooker = [[NSFileManager defaultManager] fileExistsAtPath:@"/usr/lib/libhooker.dylib"];
	BOOL isSubstitute = ([[NSFileManager defaultManager] fileExistsAtPath:@"/usr/lib/libsubstitute.dylib"] && ![[NSFileManager defaultManager] fileExistsAtPath:@"/usr/lib/substrate"]);

	if(isLibHooker || isSubstitute) {
		%init(OptimizeHooks);
	}
	else {
		%init(OptimizeHooksForSubstrate);
	}
}
