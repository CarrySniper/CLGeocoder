//
//  ViewController.m
//  CLGeocoder地理编码
//
//  Created by 思久科技 on 16/6/8.
//  Copyright © 2016年 Seejoys. All rights reserved.
//

#import "ViewController.h"

#import <CoreLocation/CoreLocation.h>

typedef void (^Coordinate2DBlock)(CLLocationCoordinate2D coordinate);

#define WEAKSELF  typeof(self) __weak weakSelf = self;

/*
  经纬度获取了有正负。经度 西经为-，东经为+。纬度 南纬为-，北纬为+.
 */

@interface ViewController ()

@property (weak, nonatomic) IBOutlet UITextField *addressTF;    //地址名称

@property (weak, nonatomic) IBOutlet UITextField *longitudeTF;  //经度

@property (weak, nonatomic) IBOutlet UITextField *latitudeTF;   //纬度

@property (weak, nonatomic) IBOutlet UITextView *infoTV;        //位置信息

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
}

#pragma mark - 编码转换事件
- (IBAction)transformationAction:(id)sender {
    [self.view endEditing:YES];
    
    self.infoTV.text = @"等待编码解析……";
    [self geocodeAddress:_addressTF.text block:^(CLLocationCoordinate2D coordinate) {
        if (coordinate.longitude != 404.0 && coordinate.latitude != 404.0) {
            self.longitudeTF.text = [NSString stringWithFormat:@"%f", coordinate.longitude];
            self.latitudeTF.text = [NSString stringWithFormat:@"%f", coordinate.latitude];
        }else{
            self.longitudeTF.text = self.latitudeTF.text = @"找不到位置";
        }
    }];
}

/**
 *  地理编码：地名—>经纬度坐标
 *
 *  @param address 地址
 *  @param block   经纬度坐标 如果失败则坐标为{-1, -1}
 */
- (void)geocodeAddress:(NSString *)address block:(Coordinate2DBlock)block
{
    if (address.length == 0) {
        CLLocationCoordinate2D coordinate = {404, 404};
        if (block) dispatch_async(dispatch_get_main_queue(), ^{
            block(coordinate);
        });
    }
    
    WEAKSELF
    //地理编码
    CLGeocoder *geocoder=[[CLGeocoder alloc]init];
    [geocoder geocodeAddressString:address completionHandler:^(NSArray<CLPlacemark *> * _Nullable placemarks, NSError * _Nullable error) {
        if (error != nil ||  placemarks.count == 0) {
            //如果有错误信息，或者是数组中获取的地名元素数量为0
            //说明没有找到
            NSLog(@"没有找到 %@", error);
            CLLocationCoordinate2D coordinate = {404, 404};
            if (block) dispatch_async(dispatch_get_main_queue(), ^{
                block(coordinate);
            });
            //位置信息
            weakSelf.infoTV.text = @"没有找到符合条件地点";
        }else{
            //编码成功，找到了具体的位置信息
            //需要的code
            
            //取出获取的地理信息数组中的第一个显示在界面上
            CLPlacemark *firstPlacemark = [placemarks firstObject];
            NSLog(@"经度：%f", firstPlacemark.location.coordinate.longitude);
            NSLog(@"纬度：%f", firstPlacemark.location.coordinate.latitude);
            CLLocationCoordinate2D coordinate = firstPlacemark.location.coordinate;
            if (block) dispatch_async(dispatch_get_main_queue(), ^{
                block(coordinate);
            });
            
            //打印查看找到的所有的位置信息
            weakSelf.infoTV.text = [NSString stringWithFormat:@"符合条件地点列表（%li个）：\n", placemarks.count];
            for (CLPlacemark *placemark in placemarks) {
                NSString *string = [NSString stringWithFormat:@"%@", [placemark addressDictionary]];
                
                weakSelf.infoTV.text = [weakSelf.infoTV.text stringByAppendingFormat:@"%@", [self replaceUnicode:string]];
            }
        }
    }];
    
}

#pragma mark - unicode编码以\u开头 把Unicode转为中文
- (NSString *)replaceUnicode:(NSString *)unicodeStr
{
    NSString *tempStr1 = [unicodeStr stringByReplacingOccurrencesOfString:@"\\u"withString:@"\\U"];
    NSString *tempStr2 = [tempStr1 stringByReplacingOccurrencesOfString:@"\""withString:@"\\\""];
    NSString *tempStr3 = [[@"\""stringByAppendingString:tempStr2] stringByAppendingString:@"\""];
    NSData *tempData = [tempStr3 dataUsingEncoding:NSUTF8StringEncoding];
    NSString* returnStr = [NSPropertyListSerialization propertyListFromData:tempData
                                                           mutabilityOption:NSPropertyListImmutable
                                                                     format:NULL
                                                           errorDescription:NULL];
    return [returnStr stringByReplacingOccurrencesOfString:@"\\r\\n"withString:@"\n"];
}

#pragma mark - 监听点击事件，结束所有编辑状态。
-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    [super touchesBegan:touches withEvent:event];
    [self.view endEditing:YES];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
