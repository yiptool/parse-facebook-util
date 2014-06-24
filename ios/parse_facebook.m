/* vim: set ai noet ts=4 sw=4 tw=115: */
//
// Copyright (c) 2014 Nikolay Zapolnov (zapolnov@gmail.com).
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.
//
#import "parse_facebook.h"
#import <yip-imports/ios/FBSession+ExtraMethods.h>
#import <yip-imports/ios/image.h>

void parseFacebookAuth(void (^ callback)(BOOL success, PFUser * user))
{
	[PFFacebookUtils logInWithPermissions:@[ @"email" ] block:^(PFUser * user, NSError * error) {
		if (error || !user)
		{
			[PFUser logOut];
			if (callback)
				callback(NO, nil);
			return;
		}

		FBRequest * requestName = [FBRequest requestForMe];
		[requestName startWithCompletionHandler:^(FBRequestConnection * connection, id result, NSError * error) {
			if (error || !result || ![result isKindOfClass:[NSDictionary class]])
			{
				[PFUser logOut];
				if (callback)
					callback(NO, nil);
				return;
			}

			NSDictionary * data = result;
			NSString * userID = data[@"id"];
			NSString * name = data[@"name"];

			[FBSession queryAvatarURLForUser:userID completion:^(NSString * url) {
				if (!url)
				{
					[PFUser logOut];
					if (callback)
						callback(NO, nil);
					return;
				}

				@try
				{
					user[@"displayName"] = name;
					user[@"displayNameLower"] = [name lowercaseString];
					user[@"facebookID"] = userID;
					user[@"facebookAvatarURL"] = url;
				}
				@catch (id e)
				{
					NSLog(@"Unable to store Facebook authentication data in PFUser: %@", e);
					[PFUser logOut];
					if (callback)
						callback(NO, nil);
					return;
				}

				[user saveInBackgroundWithBlock:^(BOOL succeeded, NSError * error) {
					if (error || !succeeded)
					{
						[PFUser logOut];
						if (callback)
							callback(NO, nil);
						return;
					}

					if (callback)
						callback(YES, user);
				}];
			}];
		}];
	}];
}

BOOL parseIsUserFacebookLinked(PFUser * user)
{
	NSString * id = user[@"facebookID"];
	return (id.length != 0);
}

void parseGetAvatarForFacebookUser(PFUser * user, void (^ callback)(UIImage * image))
{
	NSString * url = user[@"facebookAvatarURL"];

	if (url.length == 0)
	{
		if (callback)
			callback(nil);
		return;
	}

	iosAsyncDownloadImage(url, callback);
}
