### 基本使用

```objective-c
@implementation IPViewController
  
- (void)viewDidLoad {
    [super viewDidLoad];
}

+ (NSString *)returnClassMethod {
    return NSStringFromSelector(_cmd);
}

- (void)logObject:(NSString *)obj {
    NSLog(@"%@", obj);
}

@end
```

现在需要在viewDidLoad中打印```returnClassMethod```中返回的字符串只需要以下指令：

```
{
  // 所有修复指令
  "instructions": [
    {
      // 被修复的类
      "cls": "IPViewController",
      // 被修复方法
      "methodList": [
        {
          // 修复的方法selector
          "method": "viewDidLoad",
          "isStatic": false,
          // 修复后的方法实现
          "messages": [
            {
              // [super viewDidLoad]
              "receiver": "super",
              "message": "viewDidLoad"
            },
            {
              // NSString *logStr = [IPViewController returnClassMethod];
              // logStr将会被存入环境池 
              "returnType": "NSString",
              "returnObj": "logStr",
              "receiver": "IPViewController",
              "isStatic": true,
              "message": "returnClassMethod"
            },
            {
              // [self logObject:logStr];  
              "receiver": "self",
              "message": "logObject:",
              "args": [
                {
                  // 从环境池中取logStr这个对象  
                  "valueKey": "logStr"
                }
              ]
            }
          ]
        }
      ]
    }
  ]
}
```
### Block相关

block在代码的使用大部分被分为下面两个情况：

* block作为被swzzle方法的参数，需要被执行
* block作为被swzzle方法的内部实现消息的一个参数，需要被构造

#### block作为被swzzle方法的参数，需要被执行

```objective-c
@implementation IPViewController

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewDidLoad {
    [super viewDidLoad];

    [self executeReturnBlock:^NSString *(int v) {
        return [NSString stringWithFormat:@"return %d", v];
    }];
}

- (void)executeReturnBlock:(NSString *(^)(int v))block {
  // 等待被修复
}

@end
```

现在需要在```executeReturnBlock```中执行方法参数```block```，指令如下：

```
{
  "instructions": [
    {
      "cls": "IPViewController",
      "methodList": [
        {
          "method": "executeReturnBlock:",
          "isStatic": false,
          "messages": [
            {
              // 这里要标记下，消息类型是执行block  
              "isBlock": true,
              // 第一个参数，在这里就是block参数
              "blockKey": "ARG_0",
              "returnType": "NSString",
              "returnObj": "blockReturn",
              "args": [
                {
                  // 可以不提供valueKey，直接提供stringValue或者integerValue作为参数
                  // "stringValue": "string",
                  "integerValue": 666
                }
              ]
            },
            {
              "receiver": "self",
              "message": "logObject:",
              "args": [
                {
                  "valueKey": "blockReturn"
                }
              ]
            }
          ]
        }
      ]
    }
  ]
}
```

**注意**：为了方便起见，这里的block返回值如果不是id类型，会从NSInteger转换到实际类型，存在一些强转导致数值越界的问题

#### block作为被swzzle方法的内部实现的一个参数，需要被构造

```objective-c
@implementation IPMockRequest

+ (void)requestWithParameters:(NSDictionary *)parameters success:(void (^)(NSDictionary *ret))success failure:(void (^)(NSError *error))failure {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        NSError *error = nil;
        if(!error) {
          	!success ?: success(@{@"data":@"data"});
        }
        else {
            !failure ?: failure(error);
        }
    });
}

@end
  
@implementation IPViewController

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (NSInteger)produceInteger {
    return 666;
}

- (void)logNonObject:(NSInteger)value {
    NSLog(@"%d", (int)value);
}

- (void)logObject:(NSString *)obj {
    NSLog(@"%@", obj);
}

@end
```

现在需要在```viewDidLoad```中发出```IPMockRequest```的请求，指令如下：

```
{
  "instructions": [
    {
      "cls": "IPViewController",
      "methodList": [
        {
          "method": "viewDidLoad",
          "isStatic": false,
          "messages": [
            {
              "receiver": "super",
              "message": "viewDidLoad"
            },
            {
              "returnType": "NSDictionary",
              "returnObj": "requestParameters",
              "receiver": "NSDictionary",
              "message": "dictionary",
              "isStatic": true
            },
            {
              "receiver": "IPMockRequest",
              "isStatic": true,
              "message": "requestWithParameters:success:failure:",
              // success、failure只有一个被执行，所以environmentPool引用只需要+1就好了
              "environmentPoolRefCount": 1,
              "args": [
                {
                  // 第一个参数，从environmentPool中取  
                  "valueKey": "requestParameters"
                },
                {
                  // 第二个参数，类型是block  
                  "type": "block",
                  // 一个方法多个block时，这个可以为当前block产生的变量，存到environmentPool时加个前缀标识
                  "blockParameterPrefix": "success",
                  // blcok参数类型及个数
                  "blockParameterTypes": [
                    "NSDictionary"
                  ],
                  // block内部的实现，这里的结构和上面那个messages一样
                  "innerMessage": [
                    {
                      "receiver": "self",
                      "message": "logObject:",
                      "args": [
                        {
                          // 取block的第一个参数  
                          "valueKey": "BLOCK_ARG_0",
                          "blockParameterPrefix": "success"
                        }
                      ]
                    }
                  ]
                },
                {
                  "type": "block",
                  "blockParameterPrefix": "failure",
                  "blockParameterTypes": [
                    "NSDictionary"
                  ],
                  "innerMessage": [
                    {
                      "returnType": "NSInteger",
                      "returnObj": "logInteger",
                      "receiver": "self",
                      "message": "produceInteger"
                    },
                    {
                      "receiver": "self",
                      "message": "logNonObject:",
                      "args": [
                        {
                          "valueKey": "logInteger",
                          "blockParameterPrefix": "failure"
                        }
                      ]
                    }
                  ]
                }
              ]
            }
          ]
        }
      ]
    }
  ]
}
```

**注意**：这种情况下的block参数参数最多支持4个，类型用的是void *，所以像dobule之类的无法从void *转换过来，是不支持的。这点在[JSPatch](https://github.com/bang590/JSPatch)中已有相关原因论述

### if-else&while

因为没有其他语言引擎的介入，所以这些逻辑控制关键字需要自己实现一遍。因为大部分业务逻辑能使用if-else和while来实现，所以这里只实现了这两个关键字，更多关键字可以自行实现支持。例子如下：

```objective-c
@implementation IPMockRequest

+ (void)requestWithParameters:(NSDictionary *)parameters success:(void (^)(NSDictionary *ret))success failure:(void (^)(NSError *error))failure {
    // 等待被修复
}

static int i = 0;
+ (BOOL)produceBOOL {
    if (i == 5) {
        return YES;
    }
    i++;
    return NO;
}

+ (BOOL)produceYES {
    return YES;
}

@end

@implementation IPViewController

- (void)viewDidLoad {
    [super viewDidLoad];
	
    [IPMockRequest requestWithParameters:nil success:^(NSDictionary *ret) {
        [self logObject:ret];
    } failure:^(NSError *error) {
        [self logObject:error];
    }];
}

- (void)logObject:(id)obj {
    NSLog(@"%@", obj);
}

@end
```
现在需要修复```requestWithParameters:success:failure:```方法，实现内容的代码如下：

```objective-c
BOOL whileCondition = [IPMockRequest produceYES];
while(whileCondition) {
  if ([IPMockRequest produceBOOL]) {
    NSDictionary *requestData = [NSDictionary dictionary];
    success(requestData);
  }
  else {
    NSDictionary *userInfo = [NSDictionary dictionary];
    NSError *error = [[NSError alloc] initWithDomain:@"error domain" code:-1 userInfo:userInfo];
    failure(error);
  }
}
```

修复指令如下：

```
{
  "instructions": [
    {
      "cls": "IPMockRequest",
      "methodList": [
        {
          "method": "requestWithParameters:success:failure:",
          "isStatic": true,
          "messages": [
            {
              "returnType": "BOOL",
              "returnObj": "whileCondition",
              "receiver": "IPMockRequest",
              "isStatic": true,
              "message": "produceYES"
            },
            {
              // 标记为需要while
              "isWhileSnippet": true,
              "args": [
                {
                  // while循环条件
                  "valueKey": "whileCondition"
                },
                {
                  // 参数类型是while，此时innerMessage就是while块内部的实现
                  "type": "while",
                  "innerMessage": [
                    {
                      // 标记为需要if
                      "isIfSnippet": true,
                      // 这里是if条件执行的语句，返回必须要是BOOL，while条件也可以这么写
                      "message": "produceBOOL",
                      "receiver": "IPMockRequest",
                      "returnObj": "ifCondition",
                      "returnType": "BOOL",
                      "isStatic": true,
                      "args": [
                        {
                          // 参数类型是if，innerMessage为if块的实现
                          "type": "if",
                          "innerMessage": [
                            {
                              "returnType": "NSDictionary",
                              "returnObj": "requestData",
                              "receiver": "NSDictionary",
                              "message": "dictionary",
                              "isStatic": true
                            },
                            {
                              "isBlock": true,
                              "blockKey": "ARG_1",
                              "args": [
                                {
                                  "valueKey": "requestData"
                                }
                              ]
                            },
                            // 这个message的args的类型是breakWhile，表示结束while
                            {
                              "args": [
                                {
                                  "type": "breakWhile"
                                }
                              ]
                            }
                          ]
                        },
                        {
                          // 参数类型是else，innerMessage为else块的实现
                          "type": "else",
                          "innerMessage": [
                            {
                              "returnType": "NSDictionary",
                              "returnObj": "userInfo",
                              "receiver": "NSDictionary",
                              "message": "dictionary",
                              "isStatic": true
                            },
                            {
                              "returnType": "NSError",
                              "returnObj": "requestError_tmp",
                              "receiver": "NSError",
                              "message": "alloc",
                              "isStatic": true
                            },
                            {
                              "returnType": "NSError",
                              "returnObj": "requestError",
                              "receiver": "requestError_tmp",
                              "message": "initWithDomain:code:userInfo:",
                              "args": [
                                {
                                  "stringValue": "error domain"
                                },
                                {
                                  "integerValue": -1
                                },
                                {
                                  "valueKey": "userInfo"
                                }
                              ]
                            },
                            {
                              "isBlock": true,
                              "blockKey": "ARG_2",
                              "args": [
                                {
                                  "valueKey": "requestError"
                                }
                              ]
                            }
                          ]
                        }
                      ]
                    }
                  ]
                }
              ]
            }
          ]
        }
      ]
    }
  ]
}
```



### 说明

* 原方法：`IPORI_XXXX`
* 方法的参数的`valueKey`：`ARG_X`，索引X从0开始
* block的参数valueKey：`BLCOK_ARG_X`，索引X从0开始
* `arg.type`目前有：`if`、`else`、 `while`、`breakWhile` 、`block`，用法参见上面

### TODO

上述json文件的可读性比较差，但是可以通过脚本来优化一发，可以让人写一些可读性强代码，然后通过脚本自动转成json

