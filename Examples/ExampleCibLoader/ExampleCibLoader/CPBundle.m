/*
 * CPBundle.j
 * Foundation
 *
 * Created by Francisco Tolmasky.
 * Copyright 2008, 280 North, Inc.
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA
 */

#include "CPBundle.h"

NSString *CPBundleDidLoadNotification = @"CPBundleDidLoadNotification";

/*!
    @class CPBundle
    @ingroup foundation
    @brief Groups information about an application's code & resources.
*/

NSDictionary *CPBundlesForURLStrings = {nil};

@implementation CPBundle
{
    CFBundle    *_bundle;
    id          _delegate;
}

+ (CPBundle *)bundleWithURL:(NSURL *)aURL
{
    return [[self alloc] initWithURL:aURL];
}

+ (CPBundle *)bundleWithPath:(NSString *)aPath
{
    return [self bundleWithURL:[NSURL URLWithString:aPath]];
}

+ (CPBundle *)bundleWithIdentifier:(NSString *)anIdentifier
{
    CFBundle *bundle = CFBundle.bundleWithIdentifier(anIdentifier);

    if (bundle)
    {
        var url = bundle.bundleURL(),
            cpBundle = CPBundlesForURLStrings[url.absoluteString()];

        if (!cpBundle)
            cpBundle = [self bundleWithURL:url];

        return cpBundle;
    }

    return nil;
}

+ (CPBundle *)bundleForClass:(Class)aClass
{
    return [self bundleWithURL:CFBundle.bundleForClass(aClass).bundleURL()];
}

+ (CPBundle *)mainBundle
{
    return [CPBundle bundleWithPath:CFBundle.mainBundle().bundleURL()];
}

- (id)initWithURL:(NSURL *)aURL
{
    aURL = new CFURL(aURL);

    var URLString = aURL.absoluteString(),
        existingBundle = CPBundlesForURLStrings[URLString];

    if (existingBundle)
        return existingBundle;

    self = [super init];

    if (self)
    {
        _bundle = new CFBundle(aURL);
        CPBundlesForURLStrings[URLString] = self;
    }

    return self;
}

- (id)initWithPath:(NSString *)aPath
{
    return [self initWithURL:[NSURL URLWithString:aPath]];
}

- (Class)classNamed:(NSString *)aString
{
    // ???
}

- (NSURL *)bundleURL
{
    return _bundle.bundleURL();
}

- (NSString *)bundlePath
{
    return [[self bundleURL] path];
}

- (NSString *)resourcePath
{
    return [[self resourceURL] path];
}

- (NSURL *)resourceURL
{
    return _bundle.resourcesDirectoryURL();
}

- (Class)principalClass
{
    var className = [self objectForInfoDictionaryKey:@"CPPrincipalClass"];

    //[self load];

    return className ? CPClassFromString(className) : nil;
}

- (NSString *)bundleIdentifier
{
    return _bundle.identifier();
}

- (BOOL)isLoaded
{
    return _bundle.isLoaded();
}

- (NSString *)pathForResource:(NSString *)aFilename
{
    return _bundle.pathForResource(aFilename);
}

- (NSDictionary *)infoDictionary
{
    return _bundle.infoDictionary();
}

- (id)objectForInfoDictionaryKey:(NSString *)aKey
{
    return _bundle.valueForInfoDictionaryKey(aKey);
}

- (void)loadWithDelegate:(id)aDelegate
{
    _delegate = aDelegate;

    _bundle.addEventListener("load", function()
    {
        [_delegate bundleDidFinishLoading:self];
        // userInfo should contain a list of all classes loaded from this bundle. When writing this there
        // seems to be no efficient way to get it though.
        [[CPNotificationCenter defaultCenter] postNotificationName:CPBundleDidLoadNotification object:self userInfo:nil];
    });

    _bundle.addEventListener("error", function()
    {
        CPLog.error("Could not find bundle: " + self);
    });

    _bundle.load(YES);
}

- (NSArray *)staticResourceURLs
{
    var staticResourceURLs = [],
        staticResources = _bundle.staticResources(),
        index = 0,
        count = [staticResources count];

    for (; index < count; ++index)
        [staticResourceURLs addObject:staticResources[index].URL()];

    return staticResourceURLs;
}

- (NSArray *)environments
{
    return _bundle.environments();
}

- (NSString *)mostEligibleEnvironment
{
    return _bundle.mostEligibleEnvironment();
}

- (NSString *)description
{
    return [super description] + "(" + [self bundlePath] + ")";
}

@end
