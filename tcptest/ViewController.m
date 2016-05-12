//
//  ViewController.m
//  tcptest
//
//  Created by luodp on 16/4/18.
//  Copyright © 2016年 zhanghao. All rights reserved.
//

#include <stdio.h>
#include <sys/socket.h>
#include <sys/types.h>
#include <netinet/in.h>
#import "ViewController.h"
#include <stdlib.h>
#include <errno.h>

#import <SystemConfiguration/CaptiveNetwork.h>

#include <netinet/in.h>
#include <string.h>
#include <unistd.h>
#include <arpa/inet.h>
#include <ifaddrs.h>
#include <dlfcn.h>


@interface ViewController (){
    CLGeocoder *_coder;
    //存储上一次的位置
}

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    
    // Do any additional setup after loading the view, typically from a nib.
    int fd = socket(AF_INET, SOCK_STREAM, 0);
    
    struct sockaddr_in addr;
    addr.sin_addr.s_addr = 0;
    addr.sin_port = htons(8080);
    addr.sin_family = AF_INET;
    
    struct sockaddr_in clientAddr;
//    clientAddr.sin_addr.s_addr = 0;
//    clientAddr.sin_port = htons(INADDR_ANY);
//    clientAddr.sin_family = AF_INET;
    int len = sizeof(socklen_t);
    
    
    int ret = bind(fd, (struct sockaddr*)&addr, sizeof(addr));
    if(ret < 0)
    {
        perror("bind");
        return ;
    }
    
    listen(fd, 10);
    
    
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        while(1)
        {
            // this is new connect
            int conn = accept(fd, (struct sockaddr *)&clientAddr, &len);
            
            if(conn > 0)
            {
                printf("has new connect %d\n", conn);
                
                char buf[1024];
                recv(conn, buf, sizeof(buf), 0);
                printf("%s \n",inet_ntoa(clientAddr.sin_addr));
                printf("recv data is: %s\n", buf);
                
                send(conn, "hello ack", 10, 0);
            }
        }
    });
//    
//    while (1) {
//        [self sendUDPDataPackage];
//        sleep(10);
//    }
//  
    self.view.backgroundColor=[UIColor whiteColor];
    //1.创建定位管理对象
    _manager=[[CLLocationManager alloc]init];
    _coder=[[CLGeocoder alloc]init];
    //2.设置属性 distanceFilter、desiredAccuracy
    _manager.distanceFilter=kCLDistanceFilterNone;//实时更新定位位置
    _manager.desiredAccuracy=kCLLocationAccuracyBest;//定位精确度
    if([_manager respondsToSelector:@selector(requestAlwaysAuthorization)])
    {
        [_manager requestAlwaysAuthorization];
    }
    //该模式是抵抗程序在后台被杀，申明不能够被暂停
    _manager.pausesLocationUpdatesAutomatically=NO;
    //3.设置代理
    _manager.delegate=self;
    //4.开始定位
    [_manager startUpdatingLocation];
    //5.获取朝向
    [_manager startUpdatingHeading];
    
    

    
}

#pragma mark-CLLocationManager代理方法
//定位失败时调用的方法
-(void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error
{
    NSLog(@"%@",error);
}
//定位成功调用的的方法
-(void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations
{
    if(locations.count>0)
    {
        //        获取位置信息
        CLLocation *loc=[locations lastObject];
        //        获取经纬度的结构体
        CLLocationCoordinate2D coor=loc.coordinate;
        CLLocation *location=[[CLLocation alloc]initWithLatitude:coor.latitude longitude:coor.longitude];
        [_coder reverseGeocodeLocation:location completionHandler:^(NSArray *placemarks, NSError * error) {
            CLPlacemark *pmark=[placemarks firstObject];
            NSLog(@"%@",pmark.addressDictionary);
            NSString *city=pmark.addressDictionary[@"City"];
            if([city hasSuffix:@"市辖区"])
                city=[city substringToIndex:city.length-3];
            if([city hasSuffix:@"市"])
                city=[city substringToIndex:city.length-1];
            NSLog(@"%@",city);
        }];
    }
}



-(int)sendUDPDataPackage{
    char message[40] = "dsafasdfsadfsadf";
    int brdcFd;
    brdcFd = socket(PF_INET, SOCK_DGRAM, 0);
    if (brdcFd == -1) {
        printf("socket fail\n");
        return -1;
    }
    int optval = 1;
    NSLog(@"setsockopt:%d",setsockopt(brdcFd, SOL_SOCKET, SO_BROADCAST, &optval, sizeof(optval)));
    struct sockaddr_in theirAddr;
    memset(&theirAddr, 0, sizeof(struct sockaddr_in));
    theirAddr.sin_family = AF_INET;
    theirAddr.sin_addr.s_addr = inet_addr("255.255.255.255");
    theirAddr.sin_port = htons(43708);
    
    
    int sendBytes;
    if ((sendBytes = sendto(brdcFd, message, strlen(message), 0, (struct sockaddr *)&theirAddr, sizeof(struct sockaddr_in)))==-1) {
        printf("sendto fail,error = %d\n",errno);
        return -1;
    }
    printf("message = %s,msglen = %zu,sendBytes = %d\n",message,strlen(message),sendBytes);
    close(brdcFd);
    return 0;
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
