//
//  TodayViewController.m
//  GitHubNotificationTodayExtension
//
//  Created by 叔 陈 on 26/11/2016.
//  Copyright © 2016 叔 陈. All rights reserved.
//

#import "TodayViewController.h"
#import <NotificationCenter/NotificationCenter.h>
#import "SCGraphView.h"
#import "UIView+ViewFrameGeometry.h"
#import "SCFollowerAndStarManager.h"
#import "SCDefaultsManager.h"
#import "SCStarGraphView.h"
#import "SCStar.h"
#import "DateTools.h"

@interface TodayViewController () <NCWidgetProviding>
{
    BOOL accountHasSet;
    NSString *userName;
    NSString *userToken;
    NSArray *starDataArray;
    
    UIButton *tapToSetButton;
    UIButton *tapToHelpButton;
}

@property (nonatomic, strong) SCGraphView *followerGraphView;
@property (nonatomic, strong) SCStarGraphView *starGraphView;

@end

@implementation TodayViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    accountHasSet = NO;
    
    _followerGraphView = [[SCGraphView alloc] initWithFrame:CGRectMake(10.0f, 110.0f, self.view.width - 30.0f, 100.0f) columns:24];
//    [self.view addSubview:_followerGraphView];
    
    _starGraphView = [[SCStarGraphView alloc] initWithFrame:CGRectMake(10.0f, 0.0f, self.view.width - 30.0f, 100.0f)];
    [self.view addSubview:_starGraphView];
    
    tapToSetButton = [[UIButton alloc] initWithFrame:CGRectMake(0.0f, 0.0f, self.view.width, 100.0f)];
    tapToSetButton.backgroundColor = [UIColor clearColor];
    tapToSetButton.titleLabel.font = [UIFont systemFontOfSize:17.0f];
    tapToSetButton.titleLabel.numberOfLines = 2;
    [tapToSetButton setTitleColor:[UIColor lightGrayColor] forState:UIControlStateNormal];
    tapToSetButton.titleLabel.textAlignment = NSTextAlignmentCenter;
    [tapToSetButton setTitle:@"Tap to authenticate your \n Github Account" forState:UIControlStateNormal];
    [tapToSetButton addTarget:self action:@selector(goSettingsButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:tapToSetButton];

    self.extensionContext.widgetLargestAvailableDisplayMode = NCWidgetDisplayModeExpanded;
    
    if (![[[SCDefaultsManager sharedManager] getUserName] isEqualToString:@""] && ![[[SCDefaultsManager sharedManager] getUserToken] isEqualToString:@""]) {
        [[SCFollowerAndStarManager sharedManager] refreshData];
        [[SCFollowerAndStarManager sharedManager] setCompletionBlock:^(id object){
            NSLog(@"didFinishUpdatingStarData %ld",[object count]);
            [[SCDefaultsManager sharedManager] setRenderStarArray:object];
            [self updateGraphViewWithData:[[SCDefaultsManager sharedManager] getRenderStarArray]];
        }];
    } else {
        [self updateGraphViewWithData:[[SCDefaultsManager sharedManager] getRenderStarArray]];
    }
    
    // Do any additional setup after loading the view from its nib.
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    userName = [[SCDefaultsManager sharedManager] getUserName];
    userToken = [[SCDefaultsManager sharedManager] getUserToken];
    
    if ([userName isEqualToString:@""] || [userToken isEqualToString:@""]) {
        _followerGraphView.alpha = 0.0f;
        _starGraphView.alpha = 0.0f;
        tapToSetButton.hidden = NO;
    } else {
        _followerGraphView.alpha = 1.0f;
        _starGraphView.alpha = 1.0f;
        accountHasSet = YES;
        tapToSetButton.hidden = YES;
    }
    
//    [[SCFollowerAndStarManager sharedManager] refreshData];
}

- (void)updateFollowerGraphViewWithData:(NSDictionary *)folData
{
//    folData = @{@"2016-11-28":@(5),@"2016-11-27":@(8),@"2016-11-26":@(4),@"2016-11-25":@(9),@"2016-11-24":@(2),@"2016-11-23":@(3),@"2016-11-22":@(2),@"2016-11-21":@(5),@"2016-11-20":@(7),@"2016-11-19":@(8),@"2016-11-18":@(3),@"2016-11-17":@(6),@"2016-11-16":@(1),@"2016-11-15":@(4),@"2016-11-14":@(7),@"2016-11-13":@(4),@"2016-11-12":@(4),@"2016-11-11":@(2),@"2016-11-10":@(6)};
    
    NSDate *today = [NSDate date];
    NSCalendar *cal = [NSCalendar currentCalendar];
    NSDateComponents *components = [cal components:(NSCalendarUnitDay) fromDate:today];
    [components setDay:1];
    
    NSMutableArray *tmp = [NSMutableArray array];
    for (NSInteger i = 0;i < 24;i ++) {
        [components setDay:-i];
        NSDate *date = [cal dateByAddingComponents:components toDate:today options:0];
        NSString *key = [NSString stringWithFormat:@"%ld-%ld-%ld",date.year,date.month,date.day];
        if ([folData objectForKey:key]) {
            [tmp addObject:@([[folData objectForKey:key] integerValue] / 10.0f)];
        } else {
            [tmp addObject:@(0.0f)];
        }
    }
    
    [_followerGraphView refreshWithFollwers:tmp];
}

- (void)updateGraphViewWithData:(NSArray *)starData
{
    NSMutableDictionary *tempDictionary = [NSMutableDictionary dictionary];
    
    for (NSDictionary *item in starData) {
        NSDate *date = [item objectForKey:@"date"];
        NSString *key = [NSString stringWithFormat:@"%ld-%ld-%ld",date.year,date.month,date.day];
        if ([tempDictionary objectForKey:key]) {
            NSInteger tmp = [[tempDictionary objectForKey:key] integerValue];
            if (tmp <= 99) {
                [tempDictionary setValue:@(tmp + 1) forKey:key];
            }
        } else {
            [tempDictionary setValue:@(1) forKey:key];
        }
    }
    // Sort all date values into a dictionary with same date string key
    
    NSMutableArray *stars = [NSMutableArray array];
    
    NSDate *today = [NSDate date];
    NSCalendar *cal = [NSCalendar currentCalendar];
    NSDateComponents *components = [cal components:(NSCalendarUnitDay) fromDate:today];
    [components setDay:1];
    
    NSInteger weekDay = today.weekday;
    NSMutableArray * thisWeekArray = [NSMutableArray array];
    for (int weekDayIndex = 1; weekDayIndex <= weekDay; weekDayIndex ++)
    {
        [components setDay: - (weekDay - weekDayIndex)];
        NSDate *date = [cal dateByAddingComponents:components toDate:today options:0];
        NSString *key = [NSString stringWithFormat:@"%ld-%ld-%ld",date.year,date.month,date.day];
        
        SCStar *star = [[SCStar alloc] init];
        CGFloat value = [[tempDictionary objectForKey:key] integerValue] / 10.0f;
        if (value > 1.0f) {
            value = 1.0f;
        }
        
        star.color = [self colorForValue:value];
        star.date = date;
        star.weekDay = [NSNumber numberWithInteger:date.weekday];
        star.month = [NSNumber numberWithInteger:date.month];
        [thisWeekArray addObject:star];
    }
    [stars addObject:thisWeekArray];
    
    for (int weekFromNow = 0; weekFromNow < 30; weekFromNow ++)
    {
        NSMutableArray * thatWeekArray = [NSMutableArray array];
        for (int weekDayIndex = 1; weekDayIndex <= 7; weekDayIndex ++)
        {
            [components setDay: - (weekFromNow * 7 + weekDay - weekDayIndex + 7)];
            NSDate *date = [cal dateByAddingComponents:components toDate:today options:0];
            NSString *key = [NSString stringWithFormat:@"%ld-%ld-%ld",date.year,date.month,date.day];
            
            SCStar *star = [[SCStar alloc] init];
            CGFloat value = [[tempDictionary objectForKey:key] integerValue] / 10.0f;
            if (value > 1.0f) {
                value = 1.0f;
            }
            
            star.color = [self colorForValue:value];
            star.date = date;
            star.weekDay = [NSNumber numberWithInteger:date.weekday];
            star.month = [NSNumber numberWithInteger:date.month];
            [thatWeekArray addObject:star];
        }
        [stars addObject:thatWeekArray];
    }
    [self.starGraphView refreshFromStars:stars];
    
    starDataArray = starData;
}

- (UIColor *)colorForValue:(CGFloat)value
{
    if (value == 1.0f) {
        return [UIColor colorWithRed:85/255.0f green:68/255.0f blue:0.0f alpha:1.0f];
    } else if (value < 1.0f && value >= 0.7f) {
        return [UIColor colorWithRed:128/255.0f green:107/255.0f blue:21/255.0f alpha:1.0f];
    } else if (value < 0.7f && value >= 0.3f) {
        return [UIColor colorWithRed:212/255.0f green:191/255.0f blue:106/255.0f alpha:1.0f];
    } else if (value < 0.3f && value > 0.0f) {
        return [UIColor colorWithRed:255/255.0f green:238/255.0f blue:170/255.0f alpha:1.0f];
    } else  {
        return [UIColor whiteColor];
    }
}

- (void)goSettingsButtonPressed:(id)sender
{
    NSURL *url = [NSURL URLWithString:@"sergio.chan.GitHubNotifications://"];
    [self.extensionContext openURL:url completionHandler:nil];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)widgetPerformUpdateWithCompletionHandler:(void (^)(NCUpdateResult))completionHandler {
    // Perform any setup necessary in order to update the view.
    
    // If an error is encountered, use NCUpdateResultFailed
    // If there's no update required, use NCUpdateResultNoData
    // If there's an update, use NCUpdateResultNewData

    completionHandler(NCUpdateResultNewData);
}

#pragma mark - NCWidgetProviding
- (void)widgetActiveDisplayModeDidChange:(NCWidgetDisplayMode)activeDisplayMode
                         withMaximumSize:(CGSize)maxSize
{
    if (activeDisplayMode == NCWidgetDisplayModeCompact)
    {
        self.preferredContentSize = maxSize;
        [UIView animateWithDuration:0.2
                         animations:^{
                             [self.view layoutIfNeeded]; // Called on parent view
                         } completion:^(BOOL finished) {
                             [_followerGraphView removeFromSuperview];
                         }];
    }
    else {
        self.preferredContentSize = CGSizeMake(0, 220.0);
        [self updateFollowerGraphViewWithData:[[SCDefaultsManager sharedManager] getRenderFollowersDict]];
        [self.view addSubview:_followerGraphView];

        [UIView animateWithDuration:0.2
                         animations:^{
                             [self.view layoutIfNeeded]; // Called on parent view
                         }];
    }
}
- (UIEdgeInsets)widgetMarginInsetsForProposedMarginInsets:(UIEdgeInsets)defaultMarginInsets
{
    return UIEdgeInsetsZero;
}

@end
