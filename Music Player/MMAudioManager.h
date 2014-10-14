//
//  MMAudioManager.h
//  Music Player
//
//  Created by Mathias on 25.09.14.
//  Copyright (c) 2014 Mathias. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import <UIKit/UIKit.h>
#import <MediaPlayer/MediaPlayer.h>

@interface MMAudioManager : NSObject

@property (strong, nonatomic) NSMutableArray *songsList; //list with all songs
@property (strong, nonatomic) NSMutableArray *playList; //current playlist
@property (strong, nonatomic) AVPlayer *audioPlayer;
@property (strong, nonatomic) MPMediaItem *currentSong;
@property (strong, nonatomic) NSString *currentSongTitle;
@property (strong, nonatomic) UIImage *currentArtwork;
@property int currentSongIndex;
@property BOOL isPlaying;

- (void) play;
- (void) pause;
- (void) playNext;
- (void) playPrevious;
- (void) play:(int)index;

- (void) switchAudioFile:(int)direction :(int)indexPrevious;
- (void) playerItemDidReachEnd;


@end
