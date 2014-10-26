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
@property (strong, nonatomic) AVPlayer *audioPlayer; //audio player
@property (strong, nonatomic) MPMediaItem *currentSong; //the song thats currently is playing
@property (strong, nonatomic) NSString *currentSongTitle; //title of the current song
@property (strong, nonatomic) UIImage *currentArtwork; //artwork of the current song
@property int currentSongIndex; //index in playlist of the current song
@property int playListAmountOfFiles; //amount of files in playlist
@property BOOL isPlaying; //is the player playing or not

@property (strong, nonatomic) NSMutableArray *noAlbumArtworkImages; //images used if played song has no album artwork

- (void) play;
- (void) pause;
- (void) playNext;
- (void) playPrevious;
- (void) skip:(int)direction :(float)percent;
- (void) play:(int)index;
- (BOOL) isPlayingSong:(int)index;
- (void) increaseVolume:(float)percent;
- (void) decreaseVolume:(float)percent;

- (void) modifyVolume:(int)direction :(float)percent;
- (void) switchAudioFile:(int)direction :(int)indexPrevious;
- (void) playerItemDidReachEnd;


@end
