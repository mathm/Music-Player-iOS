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

@property (strong,nonatomic) NSMutableArray *tableSliderValuesArray;

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
    // Do any additional setup after loading the view.
    MMViewController *viewController = [self.tabBarController.viewControllers objectAtIndex:0];
    NSLog(@"%@",viewController.songName);

    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    
    MPMediaQuery *everything = [[MPMediaQuery alloc] init];
    NSArray *itemsFromGenericQuery = [everything items];
    
    self.songsList = [NSMutableArray arrayWithArray:itemsFromGenericQuery];
    
    self.genreList = [[MMGenreList alloc]init];
   
    // generate sliderValueArray
    /*self.tableSliderValuesArray = [[NSMutableArray alloc]init];
    
    for(int i=0;i<self.genreList.count;i++)
    {
        NSNumber *value = [NSNumber numberWithInt:100/self.genreList.count];
        [self.tableSliderValuesArray addObject:value];
    }*/
    
    //generate genre list
    NSMutableArray *tmpArr = [[NSMutableArray alloc]init];
    
    for(MPMediaItem *song in self.songsList)
    {
        NSString *genre = [song valueForProperty: MPMediaItemPropertyGenre];
        if(genre != nil)
        {
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
    cell.labelGenre.font = [UIFont systemFontOfSize:12];
    cell.labelGenre.text = [[self.genreList.genreList objectAtIndex:indexPath.row] name];
    
    //percent label
    cell.labelPercent.font = [UIFont systemFontOfSize:12];
    cell.labelPercent.text = [[NSNumber numberWithFloat:cell.sliderPercent.value] stringValue];
    
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
    NSLog(@"TEMP: %i",tmp);
    // if the overall value is > 100, take the smalest value and reduce his value by 1
    while(tmp>100)
    {
        [self.genreList generateNewListRanking];
        
        for (MMGenre *genre in self.genreList.genreList) {
            NSLog(@"cellPosition:%li, percentage %i, rank %i",genre.cellPosition, genre.percentage, genre.rank);
        }
        
        /*long cellPositionMinValue = 0;
        for(int i=0; i<self.genreList.genreList.count;i++)
        {
            int tmpSliderValue = [[self.genreList.genreList objectAtIndex:i] percentage];
            int minValueTmp = [[self.genreList.genreList objectAtIndex:cellPositionMinValue] percentage];

            if(tmpSliderValue < minValueTmp && tmpSliderValue>0)
                cellPositionMinValue = i;
            
            
        }*/
        long cellPositionMinValue = 0;
        /*for (int i=0; i<self.genreList.genreList.count; i++) {
            if ([[self.genreList.genreList objectAtIndex:i] percentage]>0 && [[self.genreList.genreList objectAtIndex:i] cellPosition] != cellPosition) {
                cellPositionMinValue = i;
            }
        }*/
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
        
        //NSNumber *minValueTmp = [NSNumber numberWithInt:[[self.tableSliderValuesArray objectAtIndex:cellPositionMinValue] intValue]];
        int minValue = [[self.genreList.genreList objectAtIndex:cellPositionMinValue] percentage];
        int newValue = 0;
        
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
        //NSNumber *newValueTmp = [NSNumber numberWithInt:newValue];
        //[self.tableSliderValuesArray replaceObjectAtIndex:cellPositionMinValue withObject:newValueTmp];
        [[self.genreList.genreList objectAtIndex:cellPositionMinValue] setPercentage:newValue];
    }
    
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
