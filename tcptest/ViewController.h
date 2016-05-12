//
//  ViewController.h
//  tcptest
//
//  Created by luodp on 16/4/18.
//  Copyright © 2016年 zhanghao. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>
@interface ViewController : UIViewController<CLLocationManagerDelegate>
//定位管理对象
@property(nonatomic,strong)CLLocationManager* manager;

@end

