//
//  AppDelegate.m
//  tcptest
//
//  Created by luodp on 16/4/18.
//  Copyright © 2016年 zhanghao. All rights reserved.
//

#import "AppDelegate.h"
#import "ProccessHelper.h"
#import <CoreLocation/CoreLocation.h>
#import "ViewController.h"
@interface AppDelegate ()

@property(strong,nonatomic)NSArray *systemprocessArray;

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
       return YES;
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    if([CLLocationManager significantLocationChangeMonitoringAvailable])
    {
        ViewController * vc=(ViewController *)self.window.rootViewController;
        [vc.manager stopUpdatingLocation];
        [vc.manager startMonitoringSignificantLocationChanges];
    }
    else
    {
        NSLog(@"significant Location Change not Available");
    }
    

    
}

- (void)applicationWillResignActive:(UIApplication *)application
{
}
- (void)applicationWillEnterForeground:(UIApplication *)application
{
}
- (void)applicationDidBecomeActive:(UIApplication *)application
{
    if([CLLocationManager significantLocationChangeMonitoringAvailable])
    {
        ViewController * vc=(ViewController *)self.window.rootViewController;
        [vc.manager stopMonitoringSignificantLocationChanges];
        [vc.manager startUpdatingLocation];
    }
    else
    {
        NSLog(@"significant Location Change not Available");
    }

}
- (void)applicationWillTerminate:(UIApplication *)application
{
}




@end
