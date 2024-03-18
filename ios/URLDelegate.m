#import "URLDelegate.h"
#import <React/RCTLinkingManager.h>

@implementation URLDelegate

- (BOOL)braze:(Braze *)braze shouldOpenURL:(BRZURLContext *)context {
  if ([[context.url.host lowercaseString] isEqualToString:@"www.kfc.com"]) {
    [RCTLinkingManager application:[UIApplication sharedApplication] openURL:[NSURL URLWithString:[context.url absoluteString]] options:@{}];
    return NO;
  }
  // Let Braze handle links otherwise
  return YES;
}

@end
