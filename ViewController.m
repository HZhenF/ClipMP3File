//
//  ViewController.m
//  ClipMP3File
//
//  Created by HZhenF on 2017/5/22.
//  Copyright © 2017年 Huangzhengfeng. All rights reserved.
//

#import "ViewController.h"
#import "Masonry.h"
#import <AVFoundation/AVFoundation.h>
#import "NSString+MusicTimeExtension.h"
#import "CALayer+PauseAimate.h"

//音频处理
#import <AudioToolbox/AudioToolbox.h>

#define ScreenWidth [UIScreen mainScreen].bounds.size.width
#define ScreenHeight [UIScreen mainScreen].bounds.size.height

#define ratioW ScreenWidth/414
#define ratioH ScreenHeight/736

@interface ViewController ()<AVAudioPlayerDelegate,UITextFieldDelegate,UIScrollViewDelegate>

@property(nonatomic,strong) UIProgressView * progress;
/**声音控制*/
@property(nonatomic,strong) UISlider *slider;
/**音乐进度控制*/
@property(nonatomic,strong) UISlider *musicSlider;

@property(nonatomic,strong) AVAudioPlayer *musicPlayer;
/**监控音频播放进度*/
@property(nonatomic,strong) NSTimer *timer;

@property(nonatomic,strong) UILabel *leftTimeShow;

@property(nonatomic,strong) UILabel *rightTimeShow;

@property(nonatomic,strong) UIImageView *imageView;

@property(nonatomic,assign) BOOL playingFlag;

@property(nonatomic,strong) UIButton *playBtn;

@property(nonatomic,strong) NSFileManager *manager;

@property(nonatomic,strong) UITextField *startTF;

@property(nonatomic,strong) UITextField *endTF;

@property(nonatomic,strong) UILabel *startLabel;

@property(nonatomic,strong) UILabel *endLabel;

@property(nonatomic,strong) UIScrollView *scrollView;

@property(nonatomic,strong) UIButton *clipBtn;

@end

//文件输出路径
//static NSString *mainPath = <#请输入您的电脑路径，最好新建一个文件夹作为实验对象#>
static NSString *mainPath = @"/Users/huangzhenfeng/Desktop/可删除2/未命名文件夹";

@implementation ViewController

-(UIButton *)clipBtn
{
    if (!_clipBtn) {
        _clipBtn = [[UIButton alloc] initWithFrame:CGRectMake(CGRectGetMinX(self.playBtn.frame) - 80*ratioW - 20, CGRectGetMinY(self.playBtn.frame),80*ratioW, 50*ratioW)];
        [_clipBtn setTitle:@"开始截取" forState:UIControlStateNormal];
        _clipBtn.titleLabel.font = [UIFont systemFontOfSize:13.0];
        _clipBtn.titleLabel.textAlignment = NSTextAlignmentCenter;
        _clipBtn.titleLabel.textColor = [UIColor whiteColor];
        [_clipBtn addTarget:self action:@selector(clipBtnAction) forControlEvents:UIControlEventTouchUpInside];
    }
    return _clipBtn;
}

-(UITextField *)endTF
{
    if (!_endTF) {
        _endTF = [[UITextField alloc] initWithFrame:CGRectMake(0,0, CGRectGetWidth(self.startTF.frame), CGRectGetHeight(self.startTF.frame))];
        _endTF.center = CGPointMake(CGRectGetMaxX(self.endLabel.frame) + _endTF.bounds.size.width * 0.5 + 5, self.endLabel.center.y);
        _endTF.borderStyle = UITextBorderStyleRoundedRect;
        _endTF.keyboardType = UIKeyboardTypeNumberPad;
        _endTF.background = [UIImage imageNamed:@"chat_bottom_textfield"];
        _endTF.attributedPlaceholder = [self changeAttributes:@"单位:秒"];
        [self.view addSubview:_endTF];
    }
    return _endTF;
}

-(UILabel *)endLabel
{
    if (!_endLabel) {
        _endLabel = [[UILabel alloc] initWithFrame:CGRectMake(CGRectGetMaxX(self.startTF.frame) + 20*ratioW , CGRectGetMinY(self.startLabel.frame) , CGRectGetWidth(self.startLabel.frame), CGRectGetHeight(self.startLabel.frame))];
        _endLabel.text = @"结束时间:";
        _endLabel.textAlignment = NSTextAlignmentCenter;
        _endLabel.textColor = [UIColor whiteColor];
        _endLabel.font = [UIFont systemFontOfSize:13.0];
        }
    return _endLabel;
}

-(UIScrollView *)scrollView
{
    if (!_scrollView) {
        _scrollView = [[UIScrollView alloc] initWithFrame:self.view.frame];
        _scrollView.contentSize = CGSizeMake(ScreenWidth, ScreenHeight + 5);
        _scrollView.showsVerticalScrollIndicator = NO;
        _scrollView.showsHorizontalScrollIndicator = NO;
        [self.view addSubview:_scrollView];
    }
    return _scrollView;
}

-(UILabel *)startLabel
{
    if (!_startLabel) {
        _startLabel = [[UILabel alloc] initWithFrame:CGRectMake(10*ratioW, CGRectGetMaxY(self.imageView.frame) + 100, 70*ratioW, 20*ratioH)];
        _startLabel.text = @"开始时间:";
        _startLabel.textAlignment = NSTextAlignmentCenter;
        _startLabel.textColor = [UIColor whiteColor];
        _startLabel.font = [UIFont systemFontOfSize:13.0];
    }
    return _startLabel;
}

-(UITextField *)startTF
{
    if (!_startTF) {
        _startTF = [[UITextField alloc] initWithFrame:CGRectMake(0, 0, 100*ratioW, 30*ratioH)];
        _startTF.center = CGPointMake(CGRectGetMaxX(self.startLabel.frame) + _startTF.bounds.size.width * 0.5 + 5, self.startLabel.center.y);
        _startTF.keyboardType = UIKeyboardTypeNumberPad;
        _startTF.attributedPlaceholder = [self changeAttributes:@"单位:秒"];
        _startTF.borderStyle = UITextBorderStyleRoundedRect;
        _startTF.background = [UIImage imageNamed:@"chat_bottom_textfield"];
        [self.view addSubview:_startTF];
    }
    return _startTF;
}

-(NSFileManager *)manager
{
    if (!_manager) {
        _manager = [NSFileManager defaultManager];
    }
    return _manager;
}

-(UIButton *)playBtn
{
    if (!_playBtn) {
        _playBtn = [[UIButton alloc] initWithFrame:CGRectMake(ScreenWidth - 80*ratioW, ScreenHeight - 50*ratioW, 80*ratioW, 50*ratioW)];
        [_playBtn setTitle:@"开始播放" forState:UIControlStateNormal];
        [_playBtn setTitle:@"停止播放" forState:UIControlStateSelected];
        _playBtn.titleLabel.textAlignment = NSTextAlignmentCenter;
        _playBtn.titleLabel.font = [UIFont systemFontOfSize:13.0];
        [_playBtn setTitleColor:[UIColor orangeColor] forState:UIControlStateSelected];
        [_playBtn setTitleColor:[UIColor orangeColor] forState:UIControlStateNormal];
        [_playBtn addTarget:self action:@selector(buttonAction:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _playBtn;
}

-(UIImageView *)imageView
{
    if (!_imageView) {
        _imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 100*ratioW, 100*ratioW)];
        _imageView.center = CGPointMake(ScreenWidth*0.5,self.slider.center.y + 100*ratioW);
        _imageView.layer.cornerRadius = _imageView.bounds.size.width * 0.5;
        _imageView.layer.masksToBounds = YES;
        _imageView.layer.borderWidth = 2.0;
        _imageView.layer.borderColor = [UIColor whiteColor].CGColor;
        [self.view addSubview:_imageView];
    }
    return _imageView;
}

-(UILabel *)rightTimeShow
{
    if (!_rightTimeShow) {
        _rightTimeShow = [[UILabel alloc] initWithFrame:CGRectMake(CGRectGetMaxX(self.progress.frame) + 10, CGRectGetMinY(self.leftTimeShow.frame), 40*ratioW, 20*ratioH)];
        _rightTimeShow.textColor = [UIColor whiteColor];
        _rightTimeShow.font = [UIFont systemFontOfSize:13.0];
        _rightTimeShow.textAlignment = NSTextAlignmentCenter;
        [self.view addSubview:_rightTimeShow];
    }
    return _rightTimeShow;
}

-(UILabel *)leftTimeShow
{
    if (!_leftTimeShow) {
        _leftTimeShow = [[UILabel alloc] initWithFrame:CGRectMake(10, 100*ratioH, 40*ratioW, 20*ratioH)];
        _leftTimeShow.textColor = [UIColor whiteColor];
        _leftTimeShow.font = [UIFont systemFontOfSize:13.0];
        _leftTimeShow.textAlignment = NSTextAlignmentCenter;
        [self.view addSubview:_leftTimeShow];
    }
    return _leftTimeShow;
}

-(NSTimer *)timer
{
    if (!_timer) {
        _timer = [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(playProgress) userInfo:nil repeats:YES];
        [[NSRunLoop mainRunLoop] addTimer:_timer forMode:NSRunLoopCommonModes];
    }
    return _timer;
}


-(UISlider *)musicSlider
{
    if (!_musicSlider) {
        _musicSlider = [[UISlider alloc] initWithFrame:CGRectMake(CGRectGetMinX(self.progress.frame), CGRectGetMinY(self.progress.frame) + 50, CGRectGetWidth(self.progress.frame), 40)];
        [_musicSlider setThumbImage:[UIImage imageNamed:@"player_slider_playback_thumb"] forState:UIControlStateNormal];
        _musicSlider.minimumTrackTintColor = [UIColor orangeColor];
        _musicSlider.maximumTrackTintColor = [UIColor lightGrayColor];
        _musicSlider.value = 0;
        [_musicSlider addTarget:self action:@selector(pressMusicSlider) forControlEvents:UIControlEventValueChanged];
    }
    return _musicSlider;
}

-(UISlider *)slider
{
    if (!_slider) {
        _slider = [[UISlider alloc] init];
        //高度不起作用，系统默认
        _slider.frame = CGRectMake(CGRectGetMinX(self.musicSlider.frame), CGRectGetMaxY(self.musicSlider.frame) + 50, CGRectGetWidth(self.musicSlider.frame), 40);
        //设置滑动条的最小值，可以为负值
        _slider.minimumValue = 0;
        _slider.maximumValue = 10;
        //设置滑动条的滑动位置
//        _slider.value = 30;
        //滑动条左边背景颜色
        _slider.minimumTrackTintColor = [UIColor whiteColor];
        //滑动条右边背景颜色
        _slider.maximumTrackTintColor = [UIColor grayColor];
        //设置滑块的颜色
        _slider.thumbTintColor = [UIColor grayColor];
        
        [_slider setValue:5 animated:YES];

        [_slider addTarget:self action:@selector(pressSlider) forControlEvents:UIControlEventValueChanged];
    }
    return _slider;
}

-(UIProgressView *)progress
{
    if (!_progress) {
        _progress = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleDefault];
        //高度不起作用，系统默认
        _progress.frame = CGRectMake(CGRectGetMaxX(self.leftTimeShow.frame) + 10, 100 + self.leftTimeShow.bounds.size.height*0.5 - 2, 300, 50);
        //设置进度条颜色
        _progress.trackTintColor = [UIColor lightGrayColor];
        //设置进度默认值，这个相当于百分比，0~1之间
        //    progress.progress = 0.7;
        //设置进度条上进度的颜色
        _progress.progressTintColor = [UIColor redColor];
        
        //设置进度条的背景图片
        //    progress.trackImage = [UIImage imageNamed:@"rabbit.jpg"];
        //设置进度条上进度的背景图片
        //    progress.progressImage = [UIImage imageNamed:@"1.jpg"];
        
        //设置进度值，并动画显示
        [_progress setProgress:0.0 animated:YES];
    }
    return _progress;
}



- (void)viewDidLoad {
    [super viewDidLoad];
    
    //控件加入视图
    [self addControls];
    
    //加载MP3信息
    [self initMp3Info];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyBoardWillChange:) name:UIKeyboardWillChangeFrameNotification object:nil];

}

-(void)clipBtnAction
{
    //截取音频
    [self captureSongAction];
    [self.view endEditing:YES];
    UIAlertController *alertVC = [UIAlertController alertControllerWithTitle:@"提示" message:@"截取成功!" preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        self.startTF.text = @"";
        self.endTF.text = @"";
    }];
    UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        
    }];
    [alertVC addAction:okAction];
    [alertVC addAction:cancel];
    [self presentViewController:alertVC animated:YES completion:nil];
    
}

-(NSMutableAttributedString *)changeAttributes:(NSString *)str
{
    NSMutableAttributedString *placeholderAtt = [[NSMutableAttributedString alloc] initWithString:str];
    [placeholderAtt addAttribute:NSFontAttributeName
                           value:[UIFont boldSystemFontOfSize:13.0]
                           range:NSMakeRange(0, str.length)];
    [placeholderAtt addAttribute:NSBaselineOffsetAttributeName value:[NSNumber numberWithFloat:-0.8] range:NSMakeRange(0, str.length)];
    return placeholderAtt;
}


-(void)addControls
{
    self.scrollView.delegate = self;
    
    self.view.backgroundColor = [UIColor blackColor];
    
    [self.view addSubview:self.progress];
    
    [self.view addSubview:self.slider];
    
    [self.view addSubview:self.musicSlider];
    
    [self.view addSubview:self.playBtn];
    
    [self.view addSubview:self.startLabel];
    
    [self.view addSubview:self.endLabel];
    
    [self.view addSubview:self.clipBtn];
    
    self.endTF.delegate = self;
    
    self.startTF.delegate = self;
}

-(BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [self.view endEditing:YES];
    return YES;
}

-(void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
    NSLog(@"scrollViewWillBeginDragging");
    [self.view endEditing:YES];
}

-(void)keyBoardWillChange:(NSNotification *)notification
{
    NSDictionary *dict = notification.userInfo;
    //键盘结束的frame
    CGRect endKeyboardFrame = [dict[UIKeyboardFrameEndUserInfoKey] CGRectValue];
    //键盘弹出时间
    CGFloat duration = [dict[UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    
    [UIView animateWithDuration:duration delay:0.0 options:7<<16 animations:^{
        self.view.transform = CGAffineTransformMakeTranslation(0, endKeyboardFrame.origin.y - ScreenHeight);
    } completion:^(BOOL finished) {
        
    }];
}

#pragma mark - 截取音频设置的方法

- (void)captureSongAction
{
    if ([self.startTF.text isEqualToString:@""] ||[self.endTF.text isEqualToString:@""]) {
        UIAlertController *alertVC = [UIAlertController alertControllerWithTitle:@"提示" message:@"请输入开始时间和结束时间!" preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            self.startTF.text = @"";
            self.endTF.text = @"";
        }];
        UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
            
        }];
        [alertVC addAction:okAction];
        [alertVC addAction:cancel];
        [self presentViewController:alertVC animated:YES completion:nil];
    }
    else
    {
        //获取MP3的路径
        NSString *path = [[NSBundle mainBundle] pathForResource:@"Mark Ronson,Bruno Mars - Uptown Funk" ofType:@"mp3"];
        NSURL *url = [NSURL fileURLWithPath:path];
        //1.创建AVURLAsset，可以获取里面的文件里面的信息
        AVURLAsset *songAsset = [AVURLAsset URLAssetWithURL:url options:nil];
        
        //2.创建音频文件(NSDocumentDirectory 是指程序中对应的Documents路径，而NSDocumentionDirectory对应于程序中的Library/Documentation路径，这个路径是没有读写权限的，所以看不到文件生成)
        //    NSArray *dirs = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        //获取数组里面的路径，iOS开发这里只有一个，但是Mac开发有两个
        //    NSString *documentsDirectoryPath = [dirs objectAtIndex:0];
        
        //这里我选取桌面的路径，上面的路径是沙盒路径，一般用于真实开发中
        NSString *exportPath = mainPath;
        //导出音频的路径+导出音频名字
        //因为iOS输出格式不知道.mp3,只能设置为.m4a
        NSString *tempMusicPath = [NSString stringWithFormat:@"%@/clipMp3.m4a",exportPath];
        
        //判断是否存在这个文件，如果存在，就删除这个文件
        if ([self.manager fileExistsAtPath:tempMusicPath]) {
            [self.manager removeItemAtPath:tempMusicPath error:nil];
//            NSLog(@"删除成功");
        }
        
        //3.创建音频输出会话
        AVAssetExportSession *exportSession = [AVAssetExportSession exportSessionWithAsset:songAsset presetName:AVAssetExportPresetAppleM4A];
        
        //4.设置音频截取时间区域(CMTime在Core Medio框架中)
        CMTime startTime = CMTimeMake([self.startTF.text floatValue], 1);
        CMTime stopTime = CMTimeMake([self.endTF.text floatValue], 1);
        CMTimeRange exportTimeRange = CMTimeRangeFromTimeToTime(startTime, stopTime);
        
        //5.设置音频输出会话并执行
        exportSession.outputURL = [NSURL fileURLWithPath:tempMusicPath];
        exportSession.outputFileType = AVFileTypeAppleM4A;
        exportSession.timeRange = exportTimeRange;
        [exportSession exportAsynchronouslyWithCompletionHandler:^{
            if (AVAssetExportSessionStatusCompleted == exportSession.status) {
                NSLog(@"AVAssetExportSessionStatusCompleted");
            } else if (AVAssetExportSessionStatusFailed == exportSession.status) {
                // a failure may happen because of an event out of your control
                // for example, an interruption like a phone call comming in
                // make sure and handle this case appropriately
                NSLog(@"AVAssetExportSessionStatusFailed");
            } else {
                NSLog(@"Export Session Status: %ld", (long)exportSession.status);
            }
        }];

    }
    
   }

#pragma mark - 播放音乐设置的方法


-(void)initMp3Info
{
    NSArray *mp3Array = [NSBundle pathsForResourcesOfType:@"mp3" inDirectory:[[NSBundle mainBundle] resourcePath]];
    //    NSLog(@"mp3Array = %@",mp3Array);
    for (NSString *filePath in mp3Array) {
        NSURL *url = [NSURL fileURLWithPath:filePath];
        
        //实例化音乐播放控件
        self.musicPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:url error:nil];
        self.musicPlayer.delegate = self;
        //设置音量大小，默认是1
        self.musicPlayer.volume = 1;
        //准备(缓冲)播放
        [self.musicPlayer prepareToPlay];
        
        self.leftTimeShow.text = [NSString stringWithTime:self.musicPlayer.currentTime];
        self.rightTimeShow.text = [NSString stringWithTime:self.musicPlayer.duration];
        
        AVURLAsset *mp3Asset = [AVURLAsset URLAssetWithURL:url options:nil];
        
        for (NSString *format in [mp3Asset availableMetadataFormats]) {
            
            for (AVMetadataItem *metadataItem in [mp3Asset metadataForFormat:format])
            {
                if ([metadataItem.commonKey isEqual:@"artwork"]) {
                    //提取图片
                    self.imageView.image = [UIImage imageWithData:(NSData *)metadataItem.value];
                }
                else if([metadataItem.commonKey isEqualToString:@"title"])
                {
                    //提取歌曲名
                    NSString *title = (NSString *)metadataItem.value;
                    NSLog(@"title: %@",title);
                    
                }
                else if([metadataItem.commonKey isEqualToString:@"artist"])
                {
                    //提取歌手
                    NSString *artist = (NSString *)metadataItem.value;
                    NSLog(@"artist: %@",artist);
                    
                }
                else if([metadataItem.commonKey isEqualToString:@"albumName"])
                {
                    //提取专辑名称
                    NSString *albumName = (NSString *)metadataItem.value;
                    NSLog(@"albumName: %@",albumName);
                }
            }
        }
    }
}


-(void)buttonAction:(UIButton *)sender
{
    if (sender.selected) {
        sender.selected = !sender.selected;
        //暂停播放
        [self.musicPlayer pause];
        //销毁计时器
        [self.timer invalidate];
        self.timer = nil;
        //暂停动画
        [self.imageView.layer pauseAnimate];
    
    }
    else
    {
        sender.selected = !sender.selected;
        //开始播放音乐
        [self.musicPlayer play];
        //开始计时器
        [self timer];
        if (self.playingFlag) {
            //恢复动画
            [self.imageView.layer resumeAnimate];
        }
        else
        {
            //开始动画
            [self startIconViewAnimate];
            self.playingFlag = 1;
        }

    }
}

- (void)startIconViewAnimate
{
    //1.创建基本动画
    CABasicAnimation *rotateAnim = [CABasicAnimation animationWithKeyPath:@"transform.rotation.z"];
    //2.设置属性
    rotateAnim.fromValue = @(0);
    rotateAnim.toValue = @(M_PI * 2);
    rotateAnim.repeatCount = NSIntegerMax;
    rotateAnim.duration = 40;
    //3.添加动画到图上
    [self.imageView.layer addAnimation:rotateAnim forKey:nil];
}

-(void)pressMusicSlider
{
    self.musicPlayer.currentTime = self.musicSlider.value * self.musicPlayer.duration;
}

-(void)playProgress
{
    //显示当前播放进度
    self.progress.progress = self.musicPlayer.currentTime / self.musicPlayer.duration;
    //实时更新时间
    self.leftTimeShow.text = [NSString stringWithTime:self.musicPlayer.currentTime];
    //滑块更新位置
    self.musicSlider.value = self.musicPlayer.currentTime / self.musicPlayer.duration;
}


-(void)pressSlider
{
    self.musicPlayer.volume = self.slider.value;
}

//播放完成
-(void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag
{
    
}

//播放失败
-(void)audioPlayerDecodeErrorDidOccur:(AVAudioPlayer *)player error:(NSError *)error
{
    
}


-(void)settingAVPlayer
{
    //音乐播放状态
    //        BOOL isPlaying = self.musicPlayer.isPlaying;
    
    //音乐通道数
    //        self.musicPlayer.numberOfChannels;
    
    //获取音乐长度,单位秒
    //        NSTimeInterval duration = self.musicPlayer.duration;
    
    //获取与输出设备相关联的当前播放进度
    //        NSTimeInterval deviceCurrentTime = self.musicPlayer.deviceCurrentTime;
    
    //获取当前音乐的路径
    //        NSURL *currentMusicURL = self.musicPlayer.url;
    
    //获取当前音乐文件的数据
    //        NSData *currentMusicData = self.musicPlayer.data;
    
    //设置播放速速
    //        self.musicPlayer.rate = 0.5;
    
    //设置音乐从指定处开始播放
    //        self.musicPlayer.currentTime = 60;
    
    //设置循环播放次数,＝ 0：只播放一次（默认），> 0：播放设置的次数，< 0：循环播放
    //        self.musicPlayer.numberOfLoops = 0;
    
    //在指定的时间播放音乐
    //        [self.musicPlayer playAtTime:[[NSDate dateWithTimeIntervalSinceNow:10] timeIntervalSince1970]];
    
    //停止播放音乐
    //        [self.musicPlayer stop];

    //        NSLog(@"rate = %f",self.musicPlayer.rate);
}

@end
