//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//    http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

#import "WSWebServiceProxy.h"

#import <UIKit/UIKit.h>

NSString * const WSWebServiceErrorDomain = @"WSWebServiceErrorDomain";

@implementation WSWebServiceProxy
{
    NSString *_multipartBoundary;
}

static NSString * const kApplicationJSON = @"application/json";

- (instancetype)initWithSession:(NSURLSession *)session serverURL:(NSURL *)serverURL
{
    self = [super init];

    if (self) {
        _session = session;
        _serverURL = serverURL;

        _encoding = WSEncodingApplicationXWWWFormURLEncoded;

        _multipartBoundary = [[NSUUID new] UUIDString];
    }

    return self;
}

- (NSURLSessionTask *)invoke:(WSMethod)method path:(NSString *)path
    arguments:(NSDictionary *)arguments
    body:(NSData *)body
    resultHandler:(void (^)(id, NSError *))resultHandler
{
    return [self invoke:method path:path arguments:arguments body: body responseHandler:^id (NSData *data, NSString *contentType, NSError **error) {
        id result = nil;

        if ([contentType hasPrefix:kApplicationJSON]) {
            result = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:error];
        } else if ([contentType hasPrefix:@"image/"]) {
            result = [UIImage imageWithData:data];
        } else if ([contentType hasPrefix:@"text/"]) {
            result = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        } else {
            *error = [NSError errorWithDomain:WSWebServiceErrorDomain code:-1 userInfo:@{
                NSLocalizedDescriptionKey:@"Unsupported response encoding."
            }];
        }

        return result;
    } resultHandler:resultHandler];
}

- (NSURLSessionTask *)invoke:(WSMethod)method path:(NSString *)path
    arguments:(NSDictionary<NSString *, id> *)arguments
    body:(NSData *)body
    responseHandler:(id (^)(NSData *data, NSString *contentType, NSError **error))responseHandler
    resultHandler:(void (^)(id, NSError *))resultHandler;
{
    // TODO
    return nil;
}

@end
