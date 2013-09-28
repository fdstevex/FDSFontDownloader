//
//  FDSFontDownloader.m
//  Created by Steve Tibbett on 16/08/13.
//  Copyright (c) 2013 Fall Day Software Inc. All rights reserved.
//

#import "FDSFontDownloader.h"
#import <CoreText/CoreText.h>

@implementation FDSFontDownloader

- (void)downloadFontNamed:(NSString *)fontName
{
    if (fontName == nil) {
        NSLog(@"No font name specified");
        return;
    }
    
    NSArray *array = [[NSUserDefaults standardUserDefaults] valueForKey:@"fontURLs"];
    NSMutableArray *fontURLs = [NSMutableArray arrayWithArray:array];
    for (NSString *urlString in fontURLs) {
        NSURL *url = [NSURL URLWithString:urlString];
        CTFontManagerRegisterFontsForURL((__bridge CFURLRef)url, kCTFontManagerScopeProcess, nil);
    }
    
	UIFont* aFont = [UIFont fontWithName:fontName size:12.];
    
    // If the font is already downloaded
	if (aFont && ([aFont.fontName compare:fontName] == NSOrderedSame || [aFont.familyName compare:fontName] == NSOrderedSame)) {
        [self.delegate fontDownloadFinishedDownloadingFontNamed:fontName];
		return;
	}
	
    // Create a dictionary with the font's PostScript name.
	NSMutableDictionary *attrs = [NSMutableDictionary dictionaryWithObjectsAndKeys:fontName, kCTFontNameAttribute, nil];
    
    // Create a new font descriptor reference from the attributes dictionary.
	CTFontDescriptorRef desc = CTFontDescriptorCreateWithAttributes((__bridge CFDictionaryRef)attrs);
    
    NSMutableArray *descs = [NSMutableArray arrayWithCapacity:0];
    [descs addObject:(__bridge id)desc];
    CFRelease(desc);
    
	__block BOOL errorDuringDownload = NO;
	
	// Start processing the font descriptor..
    // This function returns immediately, but can potentially take long time to process.
    // The progress is notified via the callback block of CTFontDescriptorProgressHandler type.
    // See CTFontDescriptor.h for the list of progress states and keys for progressParameter dictionary.
    CTFontDescriptorMatchFontDescriptorsWithProgressHandler( (__bridge CFArrayRef)descs, NULL,  ^(CTFontDescriptorMatchingState state, CFDictionaryRef progressParameter) {
        
		double progressValue = [[(__bridge NSDictionary *)progressParameter objectForKey:(id)kCTFontDescriptorMatchingPercentage] doubleValue];
		
		if (state == kCTFontDescriptorMatchingDidBegin) {
			dispatch_async( dispatch_get_main_queue(), ^ {
                [self.delegate fontDownloadDidBegin];
			});
		} else if (state == kCTFontDescriptorMatchingDidFinish) {
			dispatch_async( dispatch_get_main_queue(), ^ {
                UIFont* aFont = [UIFont fontWithName:fontName size:12.];
                if (aFont == nil) {
                    [self.delegate downloadFailedForFont:fontName error:nil];
                } else {
                    [self.delegate fontDownloadFinishedDownloadingFontNamed:fontName];
                }
				
                // Log the font URL in the console
				CTFontRef fontRef = CTFontCreateWithName((__bridge CFStringRef)fontName, 0., NULL);
                CFStringRef fontURL = CTFontCopyAttribute(fontRef, kCTFontURLAttribute);
				NSLog(@"%@", (__bridge NSURL*)(fontURL));
                [fontURLs addObject:((__bridge NSURL *)fontURL).absoluteString];
                CFRelease(fontURL);
				CFRelease(fontRef);
                
                [[NSUserDefaults standardUserDefaults] setObject:fontURLs forKey:@"fontURLs"];
			});
		} else if (state == kCTFontDescriptorMatchingWillBeginDownloading) {
			dispatch_async( dispatch_get_main_queue(), ^ {
                [self.delegate fontDownloadProgress:0.0 forFont:fontName];
			});
		} else if (state == kCTFontDescriptorMatchingDidFinishDownloading) {
			dispatch_async( dispatch_get_main_queue(), ^ {
                [self.delegate fontDownloadProgress:1.0 forFont:fontName];
			});
		} else if (state == kCTFontDescriptorMatchingDownloading) {
			dispatch_async( dispatch_get_main_queue(), ^ {
                [self.delegate fontDownloadProgress:progressValue / 100.0 forFont:fontName];
			});
		} else if (state == kCTFontDescriptorMatchingDidFailWithError) {

            if (!errorDuringDownload) {
                // An error has occurred.
                // Get the error message
                NSError *error = [(__bridge NSDictionary *)progressParameter objectForKey:(id)kCTFontDescriptorMatchingError];
                
                // Set our flag
                errorDuringDownload = YES;
                
                dispatch_async( dispatch_get_main_queue(), ^ {
                    [self.delegate downloadFailedForFont:fontName error:error];
                });
            }
		} else if (state == kCTFontDescriptorMatchingStalled) {
            // This isn't an error; it will happen during normal font downloads and simply
            // indicates that download is still in progress, but no data is being received right now.
        }
        
		return (bool)YES;
	});
}

@end
