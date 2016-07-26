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


@interface ViewController ()<NSStreamDelegate>
{
    struct sockaddr_in base_addr;
    NSString * BASE_IP;
    __block BOOL connectSuccess;
    int control_socket;
    CFReadStreamRef readStream;
    CFWriteStreamRef writeStream;
}

@property (nonatomic,strong) NSInputStream *miStream;

@property (nonatomic,strong) NSOutputStream *moStream;

@property (nonatomic,copy) NSString * controlMessageBuff;


@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    connectSuccess = YES;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0),^{
        while (connectSuccess) {
            [self sendUDPDataPackage];
            sleep(5);
        }
    });

    
//    // Do any additional setup after loading the view, typically from a nib.
        int fd = socket(AF_INET, SOCK_STREAM, 0);
        
        struct sockaddr_in addr;
        addr.sin_addr.s_addr = 0;
        addr.sin_port = htons(8080);
        addr.sin_family = AF_INET;
        
        struct sockaddr_in clientAddr;

        int len = sizeof(struct sockaddr_in);
        
//            解决服务器端口重用问题
        int opt = 1;
        int setRes = setsockopt(fd,SOL_SOCKET,SO_REUSEADDR,&opt,sizeof(opt));
        if (setRes < 0) {
            perror("setsockopt");
            return ;
        }
        int ret = bind(fd, (struct sockaddr*)&addr, sizeof(addr));
        if(ret < 0)
        {
            perror("bind");
            return ;
        }
        
        listen(fd, 10);
    
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
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
                    BASE_IP = [NSString stringWithFormat:@"%s",inet_ntoa(clientAddr.sin_addr)];

                    printf("recv data is: %s\n", buf);
                    connectSuccess = NO;
                    send(conn, "hello ack", 10, 0);
                    [self connetBase];
                    close(fd);
                    break;
                }else{
                    perror("accept");
                }
                sleep(1);
            }
            while (1) {
                sleep(10);
            }
        });
    
    
    sleep(2);
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
//
            [self recvFromBase];
//
//       
    });
}

- (void)initControl {//初始化base的IP地址－－－－－－万敏
    
    memset(&base_addr, 0, sizeof(base_addr));
    base_addr.sin_len = sizeof(socklen_t);
    base_addr.sin_family = AF_INET;
    base_addr.sin_addr.s_addr = inet_addr([BASE_IP UTF8String]);
    base_addr.sin_port = htons(9999);
    bzero(&(base_addr.sin_zero),8);
}


-(BOOL)connetBase{
    [self initControl];
    control_socket = socket(PF_INET,SOCK_STREAM,0);
    
    NSString * name = [self getSetNameCommond:@"zhang"];
    char * heart = "HEADS1022OPTION_012521E321048DD";
    char * version = "HEADS0010GET_VER000";
    if (control_socket != -1) {
        //            struct timeval timeOut={0,1000*500};
        //            setsockopt(control_socket, SOL_SOCKET, SO_RCVTIMEO, (char*)&timeOut, sizeof(timeOut));
        NSLog(@"create socket success ! socket is %i \n", control_socket);
        
    }
    usleep(1000*200);
    NSLog(@"发送tcp连接的网络请求:%s",inet_ntoa(base_addr.sin_addr));
    int result = socketConnectToBase(control_socket, (struct sockaddr *)&base_addr, sizeof(struct sockaddr_in),1);
    if (result == 0) {
        send(control_socket, [name  UTF8String] ,[name length], 0);
        send(control_socket, heart, sizeof(heart), 0);
        send(control_socket, version, sizeof(version), 0);
        
        
        CFStreamCreatePairWithSocket(NULL, control_socket,  &readStream, &writeStream);
        _miStream = (__bridge NSInputStream *)readStream;
        _moStream = (__bridge NSOutputStream *)writeStream;
        
        if(_miStream == nil)
            return NO;
        [_miStream setProperty:NSStreamNetworkServiceTypeVoIP forKey:NSStreamNetworkServiceType];
        [_moStream setProperty:NSStreamNetworkServiceTypeVoIP forKey:NSStreamNetworkServiceType];
        _miStream.delegate = self;
        _moStream.delegate = self;
        [_miStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
        [_moStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
        [_miStream open];//这两句不写可能都能正常工作，我没试
        [_moStream open];//这两句不写可能都能正常工作，我没试
        [[NSRunLoop currentRunLoop]run];
        return  YES;
        
    }
    return NO;
    
    
}


-(void)recvFromBase{
    char * heart = "HEADS1022OPTION_012521E321048DD";
    char  socketBuff[512];
    int reconnectCount=0;
    while (1) {

        int n = recv(control_socket, socketBuff, sizeof(socketBuff), 0);
        if (n>0) {
             NSString *recvControlMessage = [[NSString alloc] initWithBytes:socketBuff length:n encoding:NSUTF8StringEncoding];
            recvControlMessage=[recvControlMessage stringByReplacingOccurrencesOfString:@"\r" withString:@""];
            recvControlMessage=[recvControlMessage stringByReplacingOccurrencesOfString:@"\n" withString:@""];
            if ( send(control_socket, heart, sizeof(heart), 0) == -1) {
                perror("startThread send error");
            }
            NSLog(@"%s",__FUNCTION__);
            reconnectCount=0;
            if (recvControlMessage != nil) {
                dispatch_async(dispatch_get_global_queue(0, 0), ^(void){
                
                    _controlMessageBuff = [NSString stringWithString:recvControlMessage];
                    [self analysisControlMessage];
                });
            }


        }else{
            //                    int error=-1, len=sizeof(error);
            //                    getsockopt(control_socket, SOL_SOCKET, SO_ERROR, &error, (socklen_t *)&len);
            //                    if ((0==error || ETIMEDOUT==error||EAGAIN==error)&&reconnectCount<550) {//base 50秒心跳 预留5秒
            //                        reconnectCount++;
            //                        //                        DLog(@"control socket eagain!!!");
            //                        usleep(1000*100);
            //                        neWorkStatus=[[Reachability reachabilityForLocalWiFi] currentReachabilityStatus];
            //                        if (NotReachable!=neWorkStatus) {
            //                            continue;
            //                        }
            //                    }else{
            //                        break;
            //                    }
            if (((ETIMEDOUT==errno)||(EAGAIN==errno))&&reconnectCount<1300) {//base 120秒心跳 预留10秒
                
                reconnectCount++;
                usleep(1000*100);
            }else{
                NSLog(@"break");
                CFReadStreamClose(readStream);
                CFWriteStreamClose(writeStream);
                [_miStream close];
                [_moStream close];
                break;
            }
        }

    
      }
    
}

-(void)analysisControlMessage{

    NSRange mesHeadRange=[_controlMessageBuff rangeOfString:@"HEAD"];
    if (NSNotFound==mesHeadRange.location || (mesHeadRange.location == 0 && mesHeadRange.length == 0)) {
        _controlMessageBuff=[NSString string];
        return;
    }else{
        _controlMessageBuff=[_controlMessageBuff substringFromIndex:mesHeadRange.location];
        NSLog(@"接收到的报文:%@",_controlMessageBuff);

    }
}


- (NSString *)getSetNameCommond:(NSString *)name{
    NSString *name16 = name ;
    if ([name length]<16) {
        name16 = [NSString stringWithFormat:@"%@%@",name,@"                "];
    }
    if ([name16 length]>16) {
        return [NSString stringWithFormat:@"HEADS0026DEFNAME016%@",[name16 substringToIndex:16]];
    }
    return [NSString stringWithFormat:@"HEADS0026DEFNAME016%@",name16];
}

-(int)sendUDPDataPackage{
    char message[40] = "dsafasdfsadfsadfdawdsdasdsadsddassdasa";
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




int socketConnectToBase(int socketFD,const struct sockaddr *addr,socklen_t socketLen,int waitTime)
{
    if (socketFD<0) {
        return 3;
    }
    int error=-1, len=sizeof(error);
    int flags = fcntl(socketFD,F_GETFL,0);
    fcntl(socketFD,F_SETFL,flags | O_NONBLOCK);
    int n = connect(socketFD,addr,socketLen);
    if(n < 0)
    {
        struct timeval tv;
        tv.tv_sec = waitTime;
        tv.tv_usec = 0;
        fd_set wset;
        FD_ZERO(&wset);
        FD_SET(socketFD,&wset);
        n = select(socketFD+1,NULL,&wset,NULL,&tv);
        if(n <= 0)
        { // select出错
            return 1;
        }
        else
        {
            getsockopt(socketFD, SOL_SOCKET, SO_ERROR, &error, (socklen_t *)&len);
            if(error == 0){
                fcntl(socketFD,F_SETFL,flags & ~O_NONBLOCK);  // 设为阻塞模式
                return 0;
            }
            else{
                return 2;
            }
        }
    }
    
    return n;
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
