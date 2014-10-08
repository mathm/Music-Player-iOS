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
    
    self.genreList = [[NSMutableArray alloc]init];
    
    //generate genre list
    for(MPMediaItem *song in self.songsList)
    {
        NSString *genre = [song valueForProperty: MPMediaItemPropertyGenre];
        if(genre != nil)
        {
            if ([self.genreList containsObject:genre]==false) {
                [self.genreList addObject:genre];
            }
        }
    }
   
    // generate sliderValueArray
    self.tableSliderValuesArray = [[NSMutableArray alloc]init];
    
    for(int i=0;i<self.genreList.count;i++)
    {
        NSNumber *value = [NSNumber numberWithInt:100/self.genreList.count];
        [self.tableSliderValuesArray addObject:value];
    }
    
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
    //grab the value from the tableSliderValueArray
    cell.sliderPercent.value = [[self.tableSliderValuesArray objectAtIndex:indexPath.row]intValue];
    
    //genre label
    cell.labelGenre.font = [UIFont systemFontOfSize:12];
    cell.labelGenre.text = [self.genreList objectAtIndex:indexPath.row];
    
    //percent label
    cell.labelPercent.font = [UIFont systemFontOfSize:12];
    cell.labelPercent.text = [[NSNumber numberWithFloat:cell.sliderPercent.value] stringValue];
    
    return cell;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.genreList.count;
}

/*
 called if a tableSlider Value is changed
 */
-(void) tableSliderChanged:(UISlider *)sender
{
    NSNumber *sliderValue = [NSNumber numberWithInt:sender.value];
    
    long cellPosition = sender.tag;
    
    [self.tableSliderValuesArray replaceObjectAtIndex:cellPosition withObject:sliderValue];
    
    // add all slider values to avoid a overall value > 100
    int tmp = 0;
    for(NSString *value in self.tableSliderValuesArray)
    {
        int tmpSliderValue = [value intValue];
        tmp = tmp + tmpSliderValue;
    }
    NSLog(@"TEMP: %i",tmp);
    // if the overall value is > 100, take the smalest value and reduce his value by 1
    if(tmp>=100)
    {
        long cellPositionMinValue = 0;
        for(int i=0; i<self.tableSliderValuesArray.count;i++)
        {
            int tmpSliderValue = [[self.tableSliderValuesArray objectAtIndex:i] intValue];
            int minValue = [[self.tableSliderValuesArray objectAtIndex:cellPositionMinValue] intValue];

            if(tmpSliderValue < minValue && minValue>=0)
                cellPositionMinValue = i;
            
            
            
            NSLog(@"min %@",[self.tableSliderValuesArray valueForKey:@"@min.self"]);
        }
        NSNumber *newValue = [NSNumber numberWithInt:[[self.tableSliderValuesArray objectAtIndex:cellPositionMinValue] intValue]-1];
        [self.tableSliderValuesArray replaceObjectAtIndex:cellPositionMinValue withObject:newValue];
        NSLog(@"NEW VALUE: %@",newValue);
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
