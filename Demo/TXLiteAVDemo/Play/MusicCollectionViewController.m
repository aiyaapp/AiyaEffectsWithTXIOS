//
//  MusicCollectionViewController.m
//  DeviceManageIOSApp
//
//  Created by rushanting on 2017/5/17.
//  Copyright © 2017年 tencent. All rights reserved.
//

#import "MusicCollectionViewController.h"
#import <AVFoundation/AVFoundation.h>
#import <MediaPlayer/MPMediaQuery.h>
#import <MediaPlayer/MPMediaPlaylist.h>
#import "MusicCollectionViewCell.h"
#import "UIView+Additions.h"

 NSString* const kMusicSelectedNotification = @"kMusicSelectedNotification";
 NSString* const kMusicSelectedUserInfoKeyFilePath = @"FilePath";
 NSString* const kMusicSelectedUserInfoKeyDuration = @"Duration";
 NSString* const kMusicSelectedUserInfoKeySongName = @"SongName";
 NSString* const kMusicSelectedUserInfoKeySingerName = @"SingerName";

@interface MusicCollectionViewController () {
    NSMutableArray<MPMediaItem*>* _songItems;
}

@end

@implementation MusicCollectionViewController

static NSString * const reuseIdentifier = @"MusicCollectionViewCell";

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Uncomment the following line to preserve selection between presentations
    // self.clearsSelectionOnViewWillAppear = NO;
    self.title = @"选择音乐";
    
    // Register cell classes
    [self.collectionView registerClass:[MusicCollectionViewCell class] forCellWithReuseIdentifier:reuseIdentifier];

    _songItems = [NSMutableArray new];
    // Do any additional setup after loading the view.
    MPMediaQuery *myPlaylistsQuery = [MPMediaQuery songsQuery];
    NSArray *playlists = [myPlaylistsQuery collections];
    for (MPMediaPlaylist *playlist in playlists) {
        NSArray *songs = [playlist items];
        for (MPMediaItem *song in songs) {
            [_songItems addObject:song];
        }
    }
    
    if (_songItems.count < 1) {
        self.view.backgroundColor = UIColor.darkGrayColor;
        UILabel* emptyTextLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, self.view.height / 2, self.view.width, 50)];
        emptyTextLabel.textAlignment = NSTextAlignmentCenter;
        emptyTextLabel.textColor = UIColor.lightTextColor;
        emptyTextLabel.text = @"没有找到音乐";
        emptyTextLabel.font = [UIFont systemFontOfSize:20];
        [self.view addSubview:emptyTextLabel];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

#pragma mark <UICollectionViewDataSource>

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}


- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return _songItems.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    MusicCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:reuseIdentifier forIndexPath:indexPath];
    if (indexPath.row < _songItems.count) {
        MPMediaItem* songItem = _songItems[indexPath.row];
        cell.songNameLabel.text = [songItem valueForProperty: MPMediaItemPropertyTitle];
        cell.authorNameLabel.text = [songItem valueForProperty:MPMediaItemPropertyArtist];
    }
    // Configure the cell
    
    
    return cell;
}

#pragma mark <UICollectionViewDelegate>

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    return CGSizeMake(110, 90);
}

//设置每个item水平间距
- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumInteritemSpacingForSectionAtIndex:(NSInteger)section
{
    return 7.5;
}


//设置每个item垂直间距
- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger)section
{
    return 7.5;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row < _songItems.count) {
        MPMediaItem* songItem = _songItems[indexPath.row];
        NSMutableDictionary* userinfo = [NSMutableDictionary new];
        NSString* songName = [songItem valueForProperty: MPMediaItemPropertyTitle];
        NSString* authorName = [songItem valueForProperty:MPMediaItemPropertyArtist];
        NSNumber* duration = [songItem valueForKey:MPMediaItemPropertyPlaybackDuration];
        NSString* filePath = ((NSURL*)[songItem valueForKey:MPMediaItemPropertyAssetURL]).path;
        
        [userinfo setObject:filePath forKey:kMusicSelectedUserInfoKeyFilePath];
        [userinfo setObject:songName forKey:kMusicSelectedUserInfoKeySongName];
        [userinfo setObject:authorName forKey:kMusicSelectedUserInfoKeySingerName];
        [userinfo setObject:duration forKey:kMusicSelectedUserInfoKeyDuration];
        
        [[NSNotificationCenter defaultCenter] postNotificationName:kMusicSelectedNotification object:self userInfo:userinfo];
        
        [self.navigationController popViewControllerAnimated:YES];
    }
}
/*
// Uncomment this method to specify if the specified item should be highlighted during tracking
- (BOOL)collectionView:(UICollectionView *)collectionView shouldHighlightItemAtIndexPath:(NSIndexPath *)indexPath {
	return YES;
}
*/

/*
// Uncomment this method to specify if the specified item should be selected
- (BOOL)collectionView:(UICollectionView *)collectionView shouldSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}
*/

/*
// Uncomment these methods to specify if an action menu should be displayed for the specified item, and react to actions performed on the item
- (BOOL)collectionView:(UICollectionView *)collectionView shouldShowMenuForItemAtIndexPath:(NSIndexPath *)indexPath {
	return NO;
}

- (BOOL)collectionView:(UICollectionView *)collectionView canPerformAction:(SEL)action forItemAtIndexPath:(NSIndexPath *)indexPath withSender:(id)sender {
	return NO;
}

- (void)collectionView:(UICollectionView *)collectionView performAction:(SEL)action forItemAtIndexPath:(NSIndexPath *)indexPath withSender:(id)sender {
	
}
*/

@end
