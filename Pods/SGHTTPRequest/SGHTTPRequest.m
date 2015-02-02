//
//  SGHTTPRequest.m
//  SeatGeek
//
//  Created by James Van-As on 31/07/13.
//  Copyright (c) 2013 SeatGeek. All rights reserved.
//

#import "SGHTTPRequest.h"
#import "AFNetworking.h"
#import "SGActivityIndicator.h"

NSMutableDictionary *gOperationManagers;
NSMutableDictionary *gReachabilityManagers;
SGActivityIndicator *gNetworkIndicator;
NSMutableDictionary *gRetryQueues;
SGHTTPLogging gLogging = SGHTTPLogNothing;

@interface SGHTTPRequest ()
@property (nonatomic, weak) AFHTTPRequestOperation *operation;
@property (nonatomic, strong) NSData *responseData;
@property (nonatomic, strong) NSString *responseString;
@property (nonatomic, assign) NSInteger statusCode;
@property (nonatomic, strong) NSError *error;
@property (nonatomic, assign) BOOL cancelled;
@end

@implementation SGHTTPRequest

#pragma mark - Public

+ (SGHTTPRequest *)requestWithURL:(NSURL *)url {
    return [[self alloc] initWithURL:url method:SGHTTPRequestMethodGet];
}

+ (instancetype)postRequestWithURL:(NSURL *)url {
    return [[self alloc] initWithURL:url method:SGHTTPRequestMethodPost];
}

+ (instancetype)jsonPostRequestWithURL:(NSURL *)url {
    SGHTTPRequest *request = [[self alloc] initWithURL:url method:SGHTTPRequestMethodPost];
    request.requestFormat = SGHTTPDataTypeJSON;
    return request;
}

+ (instancetype)deleteRequestWithURL:(NSURL *)url {
    return [[self alloc] initWithURL:url method:SGHTTPRequestMethodDelete];
}

+ (instancetype)putRequestWithURL:(NSURL *)url {
    return [[self alloc] initWithURL:url method:SGHTTPRequestMethodPut];
}

+ (instancetype)xmlPostRequestWithURL:(NSURL *)url {
    SGHTTPRequest *request =  [[self alloc] initWithURL:url method:SGHTTPRequestMethodPut];
    request.requestFormat = SGHTTPDataTypeXML;
    return request;
}

+ (instancetype)xmlRequestWithURL:(NSURL *)url {
    SGHTTPRequest *request =  [[self alloc] initWithURL:url method:SGHTTPRequestMethodGet];
    request.responseFormat = SGHTTPDataTypeXML;
    return request;
}

- (void)start {
    if (!self.url) {
        return;
    }

    NSString *baseURL = [SGHTTPRequest baseURLFrom:self.url];

    if (self.logRequest) {
        NSLog(@"%@", self.url);
    }

    AFHTTPRequestOperationManager *manager = [self.class managerForBaseURL:baseURL
          requestType:self.requestFormat responseType:self.responseFormat];

    id success = ^(AFHTTPRequestOperation *operation, id responseObject) {
        [self success:operation];
    };
    id failure = ^(AFHTTPRequestOperation *operation, NSError *error) {
        [self failedWithError:error operation:operation retryURL:baseURL];
    };

    switch (self.method) {
        case SGHTTPRequestMethodGet:
            _operation = [manager GET:self.url.absoluteString parameters:self.parameters
                  success:success failure:failure];
            break;
        case SGHTTPRequestMethodPost:
            _operation = [manager POST:self.url.absoluteString parameters:self.parameters
                  success:success failure:failure];
            break;
        case SGHTTPRequestMethodDelete:
            _operation = [manager DELETE:self.url.absoluteString parameters:self.parameters
                  success:success failure:failure];
            break;
        case SGHTTPRequestMethodPut:
            _operation = [manager PUT:self.url.absoluteString parameters:self.parameters
                  success:success failure:failure];
            break;
    }

    if (self.showActivityIndicator) {
        [SGHTTPRequest.networkIndicator incrementActivityCount];
    }
}

- (void)cancel {
    _cancelled = YES;
    if (self.onNetworkReachable) {
        NSString *baseURL = [SGHTTPRequest baseURLFrom:self.url];
        if ([[SGHTTPRequest retryQueueFor:baseURL] containsObject:self.onNetworkReachable]) {
            [[SGHTTPRequest retryQueueFor:baseURL] removeObject:self.onNetworkReachable];
        }
        self.onNetworkReachable = nil;
    }
    [_operation cancel]; // will call the failure block
}

#pragma mark - Private

- (id)initWithURL:(NSURL *)url method:(SGHTTPRequestMethod)method {
    self = [super init];

    self.showActivityIndicator = YES;
    self.method = method;
    self.url = url;

    // by default, use the JSON response serialiser only for SeatGeek API requests
    if ([url.host isEqualToString:@"api.seatgeek.com"]) {
        self.responseFormat = SGHTTPDataTypeJSON;
    } else {
        self.responseFormat = SGHTTPDataTypeHTTP;
    }
    self.logging = gLogging;

    return self;
}

+ (AFHTTPRequestOperationManager *)managerForBaseURL:(NSString *)baseURL
                                         requestType:(SGHTTPDataType)requestType
                                        responseType:(SGHTTPDataType)responseType {
    static dispatch_once_t token = 0;
    dispatch_once(&token, ^{
        gOperationManagers = NSMutableDictionary.new;
        gReachabilityManagers = NSMutableDictionary.new;
    });

    id key = [NSString stringWithFormat:@"%@+%@+%@",
                                        @(requestType),
                                        @(responseType),
                                        baseURL];

    AFHTTPRequestOperationManager *manager = gOperationManagers[key];
    if (manager) {
        return manager;
    }

    NSURL *url = [NSURL URLWithString:baseURL];
    manager = [[AFHTTPRequestOperationManager alloc] initWithBaseURL:url];
    gOperationManagers[key] = manager;

    //responses default to JSON
    if (responseType == SGHTTPDataTypeHTTP) {
        manager.responseSerializer = AFHTTPResponseSerializer.serializer;
    } else if (responseType == SGHTTPDataTypeXML) {
        manager.responseSerializer = AFXMLParserResponseSerializer.serializer;
    }

    if (requestType == SGHTTPDataTypeXML) {
        AFHTTPRequestSerializer *requestSerializer = manager.requestSerializer;
        [requestSerializer setValue:@"application/xml" forHTTPHeaderField:@"Content-Type"];
    } else if (requestType == SGHTTPDataTypeJSON) {
        manager.requestSerializer = AFJSONRequestSerializer.serializer;
    }

    if (!gReachabilityManagers[url.host]) {
        AFNetworkReachabilityManager *reacher = [AFNetworkReachabilityManager managerForDomain:url
              .host];
        gReachabilityManagers[url.host] = reacher;

        reacher.reachabilityStatusChangeBlock = ^(AFNetworkReachabilityStatus status) {
            switch (status) {
                case AFNetworkReachabilityStatusReachableViaWWAN:
                case AFNetworkReachabilityStatusReachableViaWiFi:
                    [self.class runRetryQueueFor:url.host];
                    break;
                case AFNetworkReachabilityStatusNotReachable:
                default:
                    break;
            }
        };
        [reacher startMonitoring];
    }

    return manager;
}

#pragma mark - Success / Fail Handlers

- (void)success:(AFHTTPRequestOperation *)operation {
    self.responseData = operation.responseData;
    self.responseString = operation.responseString;
    self.statusCode = operation.response.statusCode;
    if (!self.cancelled) {
        if (self.logResponse) {
            NSLog(@"%@ responded with status: %@\nResponse:%@",
                  self.url, @(self.statusCode), self.responseString);
        }
        if (self.onSuccess) {
            self.onSuccess(self);
        }
    }
    if (self.showActivityIndicator) {
        [SGHTTPRequest.networkIndicator decrementActivityCount];
    }
}

- (void)failedWithError:(NSError *)error operation:(AFHTTPRequestOperation *)operation
      retryURL:(NSString *)retryURL {
    if (self.showActivityIndicator) {
        [SGHTTPRequest.networkIndicator decrementActivityCount];
    }

    if (self.cancelled) {
        return;
    }

    self.error = error;
    self.responseData = operation.responseData;
    self.responseString = operation.responseString;
    self.statusCode = operation.response.statusCode;

    if (self.logErrors) {
        NSLog(@"%@ failed with status: %@\nResponse:%@\nError:%@",
              self.url, @(self.statusCode), self.responseString, error);
    }

    if (self.onFailure) {
        self.onFailure(self);
    }
    self.error = nil;

    if (self.onNetworkReachable) {
        NSURL *url = [NSURL URLWithString:retryURL];
        [[SGHTTPRequest retryQueueFor:url.host] addObject:self.onNetworkReachable];
    }
}

#pragma mark - Getters

+ (NSMutableArray *)retryQueueFor:(NSString *)baseURL {
    if (!baseURL) {
        return nil;
    }

    static dispatch_once_t token = 0;
    dispatch_once(&token, ^{
        gRetryQueues = NSMutableDictionary.new;
    });

    NSMutableArray *queue = gRetryQueues[baseURL];
    if (!queue) {
        queue = NSMutableArray.new;
        gRetryQueues[baseURL] = queue;
    }

    return queue;
}

+ (void)runRetryQueueFor:(NSString *)host {
    NSMutableArray *retryQueue = [self retryQueueFor:host];

    NSArray *localCopy = retryQueue.copy;
    [retryQueue removeAllObjects];

    for (SGHTTPRetryBlock retryBlock in localCopy) {
        retryBlock();
    }
}

+ (NSString *)baseURLFrom:(NSURL *)url {
    return [NSString stringWithFormat:@"%@://%@/", url.scheme, url.host];
}

+ (SGActivityIndicator *)networkIndicator {
    if (gNetworkIndicator) {
        return gNetworkIndicator;
    }
    gNetworkIndicator = [[SGActivityIndicator alloc] init];
    return gNetworkIndicator;
}

#pragma mark Logging

+ (void)setLogging:(SGHTTPLogging)logging {
#ifdef DEBUG
    // Logging in debug builds only.
    gLogging = logging;
#endif
}

- (BOOL)logErrors {
    return (self.logging & SGHTTPLogErrors) || (self.logging & SGHTTPLogResponses);
}

- (BOOL)logRequest {
    return self.logging & SGHTTPLogRequests;
}

- (BOOL)logResponse {
    return self.logging & SGHTTPLogResponses;
}

@end
