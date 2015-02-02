## SGHTTPRequest

A lightweight [AFNetworking](https://github.com/AFNetworking/AFNetworking) wrapper
for making HTTP requests with minimal code, and callback blocks for success,
failure, and retry. Retry blocks are called when a failed request's network resource 
becomes available again.

### CocoaPods Setup

```
pod 'SGHTTPRequest'
```

### Example GET Request

```objc
- (void)requestThings {
    NSURL *url = [NSURL URLWithString:@"http://example.com/things"];

    // create a GET request
    SGHTTPRequest *req = [SGHTTPRequest requestWithURL:url];

    // start the request in the background
    [req start];
}
```

### Example POST Request

```objc
- (void)requestThings {
    NSURL *url = [NSURL URLWithString:@"http://example.com/things"];

    // create a POST request
    SGHTTPRequest *req = [SGHTTPRequest postRequestWithURL:url];

    // set the POST fields
    req.parameters = @{@"field": @"value"};

    // start the request in the background
    [req start];
}
```

### Example with Success and Failure Handlers

If a request succeeds, the optional `onSuccess` block is called. If a request fails for any reason, the optional `onFailure` block is called.

```objc
- (void)requestThings {
    NSURL *url = [NSURL URLWithString:@"http://example.com/things"];

    // create a GET request
    SGHTTPRequest *req = [SGHTTPRequest requestWithURL:url];

    // optional success handler
    req.onSuccess = ^(SGHTTPRequest *_req) {
        NSLog(@"response:%@", _req.responseString);
    };

    // optional failure handler
    req.onFailure = ^(SGHTTPRequest *_req) {
        NSLog(@"error:%@", _req.error);
        NSLog(@"status code:%d", _req.statusCode);
    };

    // start the request in the background
    [req start];
}
```

### Example with Retry Handler

If a request failed and the network resource becomes reachable again later, the optional `onNetworkReachable` block is called.

This is useful for silently retrying on unreliable connections, thus eliminating the need for manual 'Retry' buttons. For example an attempt to fetch an image might fail due to poor wifi signal, but once the signal improves the image fetch can complete without requiring user intervention.

The easiest way to implement this is to contain your request code in a method, and call back to that method in your `onNetworkReachable` block, thus firing off a new identical request.

```objc
- (void)requestThings {
    NSURL *url = [NSURL URLWithString:@"http://example.com/things"];

    // create a GET request
    SGHTTPRequest *req = [SGHTTPRequest requestWithURL:url];

    __weak typeof(self) me = self;

    // option retry handler
    req.onNetworkReachable = ^{
        [me requestThings];
    };

    // start the request in the background
    [req start];
}
```

### Other Options

See `SGHTTPRequest.h` for more.
