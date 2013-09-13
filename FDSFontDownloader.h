//
//  FDSFontDownloader.h
//  Created by Steve Tibbett on 16/08/13.
//  Copyright (c) 2013 Fall Day Software Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol FDSFontDownloaderDelegate
- (void)fontDownloadDidBegin;
- (void)fontDownloadProgress:(float)progress forFont:(NSString *)fontName;
- (void)fontDownloadFinishedDownloadingFontNamed:(NSString *)fontName;
- (void)downloadFailedForFont:(NSString *)fontName error:(NSError *)error;
@end

@interface FDSFontDownloader : NSObject

@property (weak, nonatomic) id<FDSFontDownloaderDelegate> delegate;

- (void)downloadFontNamed:(NSString *)fontName;

@end
