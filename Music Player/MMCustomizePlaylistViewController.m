//
//  MMCustomizePlaylistViewController.m
//  Music Player
//
//  Created by Mathias on 01.10.14.
//  Copyright (c) 2014 Mathias. All rights reserved.
//

#import "MMCustomizePlaylistViewController.h"
#import "MMMusicPlayerCustomizeGenreTableViewCell.h"
#import "MMViewController.h"
#import "MMGenre.h"
#import "MMGenreList.h"

@interface MMCustomizePlaylistViewController ()

@property (strong, nonatomic) MMViewController *viewController;

@end

@implementation MMCustomizePlaylistViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    //loading viewController Data
    self.viewController = [self.tabBarController.viewControllers objectAtIndex:0];

    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    
    //music library query
    MPMediaQuery *musicLibraryWithoutCloud = [[MPMediaQuery alloc] init];
    // add filter to avoid cloud music and videos
    [musicLibraryWithoutCloud addFilterPredicate:[MPMediaPropertyPredicate predicateWithValue:[NSNumber numberWithBool:NO] forProperty:MPMediaItemPropertyIsCloudItem]];

    NSArray *itemsFromGenericQuery = [musicLibraryWithoutCloud items];
    
    self.songsList = [NSMutableArray arrayWithArray:itemsFromGenericQuery];
    
    self.genreList = [[MMGenreList alloc]init];
   
    
    //generate genre list
    NSMutableArray *tmpArr = [[NSMutableArray alloc]init];
    BOOL isNilGenre = false;
    for(MPMediaItem *song in self.songsList)
    {
        NSString *genre = [song valueForProperty: MPMediaItemPropertyGenre];
        if(genre != nil)
        {
            if ([tmpArr containsObject:genre]==false) {
                [tmpArr addObject:genre];
            }
        }
        else if (isNilGenre == false) //if there is a song without genre add genre "Other" to list
        {
            isNilGenre = true;
            genre = self.viewController.nilGenreName;
            if ([tmpArr containsObject:genre]==false) {
                [tmpArr addObject:genre];
            }
        }
    }
    
    for(NSString *genreName in tmpArr)
    {
        MMGenre *genre = [[MMGenre alloc]init];
        genre.name = genreName;
        
        [self.genreList.genreList addObject:genre];
    }
    
    //count genre files for each genre in library
    for(MPMediaItem *song in self.songsList)
    {
        NSString *genreName = [song valueForProperty: MPMediaItemPropertyGenre];
        
        if(genreName == nil)
            genreName = self.viewController.nilGenreName;
        
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"name == %@",genreName];
        NSArray *tmpArr = [self.genreList.genreList filteredArrayUsingPredicate:predicate];
        if(tmpArr.count>0)
        {
            MMGenre *genre = [tmpArr objectAtIndex:0];
            genre.filesInDatabase++;
        }
    }
    //NSLog(@"%lu",(unsigned long)self.songsList.count);
    
    [self.genreList setInitialPercentage];
    [self.genreList setInitialCellPosition];
    
    //update table
    [self.tableView reloadData];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *cellIdentifier = @"MusicPlayerCustomizeGenreTableCell";
    
    MMMusicPlayerCustomizeGenreTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    
    if(cell==nil)
    {
        NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"MusicPlayerCustomizeGenreTableCell" owner: self options:nil];
        cell = [nib objectAtIndex:0];
    }
    
    // slider
    // set a method which will get called when a slider in a cell changes value
    [cell.sliderPercent addTarget:self action:@selector(tableSliderChanged:) forControlEvents:UIControlEventValueChanged];
    //Keep a reference to each slider by assigning a tag so that we can determine which slider is being changed
    cell.sliderPercent.tag = indexPath.row;
    //grab the percentage value from genre
    cell.sliderPercent.value = [[self.genreList.genreList objectAtIndex:indexPath.row] percentage];
    
    //genre label
    cell.labelGenre.text = [[self.genreList.genreList objectAtIndex:indexPath.row] name];
    
    //percent label
    cell.labelPercent.text = [[NSNumber numberWithFloat:cell.sliderPercent.value] stringValue];
    
    //files in db label
    cell.labelFiles.text = [NSString stringWithFormat:@"%i",[[self.genreList.genreList objectAtIndex:indexPath.row]filesInDatabase]];
    
    return cell;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.genreList.genreList.count;
}

/*
 called if a tableSlider Value is changed
 */
-(void) tableSliderChanged:(UISlider *)sender
{
    int sliderValue = [[NSNumber numberWithInt:sender.value] intValue];
    
    long cellPosition = sender.tag;
    
    //[self.tableSliderValuesArray replaceObjectAtIndex:cellPosition withObject:sliderValue];
    [[self.genreList.genreList objectAtIndex:cellPosition] setPercentage:sliderValue];
    
    // add all slider values to avoid a overall value > 100
    int tmp = 0;
    for(MMGenre *genre in self.genreList.genreList)
    {
        int tmpSliderValue = [genre percentage];
        tmp = tmp + tmpSliderValue;
    }

    // if the overall value is > 100, take the smalest value and reduce his value by 1
    while(tmp>100)
    {
        // generate list ranking
        [self.genreList generateNewListRanking];
        
        long cellPositionMinValue = 0;

        //looking for genre with lowest rank to subtract redundant percentage from it
        BOOL breakOuterFor = false;
        for(int i=0;i<self.genreList.genreList.count;i++)
        {
            for(int j=0;j<self.genreList.genreList.count;j++)
            {
                if ([[self.genreList.genreList objectAtIndex:j] rank] == i) {
                    if([[self.genreList.genreList objectAtIndex:j] percentage] > 0 && [[self.genreList.genreList objectAtIndex:j] cellPosition] != cellPosition)
                    {
                        cellPositionMinValue = j;
                        breakOuterFor = true;
                        break;
                    }
                }
            }
            if(breakOuterFor) break;
        }
        
        int minValue = [[self.genreList.genreList objectAtIndex:cellPositionMinValue] percentage];
        int newValue = 0;
        
        //if its possible to subtract redundant percentage (dont shut be lower than zero)
        if (minValue-(tmp-100)>0) {
            newValue = minValue-(tmp-100);
            tmp = tmp - (tmp-100);
        } else
        {
            newValue = 0;
            tmp = tmp - minValue;
            
            if(minValue == 0 && newValue == 0)
                break;
        }

        //set new percentage to genre
        [[self.genreList.genreList objectAtIndex:cellPositionMinValue] setPercentage:newValue];
    }
    
    //update table data
    [self.tableView reloadData];
}

/*
 Button pressed, generates new playlist and switch back to playlist tab
 */
- (IBAction)buttonGenerateNewPlaylist:(id)sender {
    
    
    //generate genre list
    NSMutableArray *tmpArr = [[NSMutableArray alloc]initWithArray:self.songsList];
    NSMutableArray *tmpSongsList = [[NSMutableArray alloc]init];
    
    MPMediaItem *song;
    while(tmpSongsList.count<10)
    {
        song = [tmpArr objectAtIndex:arc4random_uniform((int)tmpArr.count)];
        [tmpSongsList addObject:song];
        [tmpArr removeObject:song];
        
        if(tmpArr.count == 0)
            break;
    }
    
    NSLog(@"%lu",(unsigned long)tmpSongsList.count);
    self.viewController.audioManager.songsList = tmpSongsList;
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"MMCustomizePlaylistNewPlaylistGeneratedNotification" object:self];
    
    self.tabBarController.selectedIndex = 0;
}

/*
 Button pressed, set genreList percentage to initial values (100/genreList.count)
 */
-(IBAction) buttonSetInitialPercentage:(id)sender
{
    [self.genreList setInitialPercentage];
    [self.tableView reloadData];
}

#pragma mark - Navigation
/*
// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
    if([segue.destinationViewController isKindOfClass:[MMViewController class]])
    {
        MMViewController *mainView = segue.destinationViewController;
        self.test = mainView.songName.text;
    }
}

*/

@end
