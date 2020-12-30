
#import <Foundation/Foundation.h>

@interface FJHPattern: NSObject
+ (BOOL) isURLRestricted: (NSURL *) url;
+ (BOOL)isPathRestricted: (NSString *)path;
+ (BOOL)isSandBoxPathRestricted: (NSString*)path;
@end

