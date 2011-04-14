/*
 * The MIT License
 * 
 * Copyright (c) 2009 Elias Klughammer
 * 
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 * 
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 * 
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 * 
 */

@import <Foundation/CPObject.j>
@import "CPWebSocket.j"

@implementation AppController : CPObject
{
	CPView			_contentView;
	CPString		_nickname;
	CPTextField		_nicknameTextField;
	CPTextField		_chatTextField;
	CPScrollView	_chatPanel;
    CPColorWell     _colorWell;
	CPWindow			_nicknameHUD;
	CPArray			_messages @accessors;
	CPCollectionView _messagesCollectionView @accessors;
    CPWebSocket webSocket;
}

- (void)applicationDidFinishLaunching:(CPNotification)aNotification
{
    var theWindow = [[CPWindow alloc] initWithContentRect:CGRectMakeZero() styleMask:CPBorderlessBridgeWindowMask];
    _contentView = [theWindow contentView];
	var bounds = [_contentView bounds];

	_messages = [];
	
	[_contentView setBackgroundColor:[CPColor colorWithHexString:@"A8C0D1"]];
	
	var tornadoLogo = [[CPImageView alloc] initWithFrame:CGRectMake(20, 70, 80, 80)];
	[tornadoLogo setImage:[[CPImage alloc] initWithContentsOfFile:@"Resources/icon.png" size:CGSizeMake(80, 80)]];
	[_contentView addSubview:tornadoLogo];
	
	var headerLabel = [[CPTextField alloc] initWithFrame:CGRectMake(100, 70, 300, 30)];
	[headerLabel setStringValue:@"Pushes like a tornado!"];
	[headerLabel setFont:[CPFont boldSystemFontOfSize:20]];
	[headerLabel setTextColor:[CPColor blackColor]];
	[_contentView addSubview:headerLabel];
	
	// Show the nick picker panel
	var _nicknameHUD = [[CPWindow alloc] initWithContentRect:CGRectMake(185, 200, 225, 125) styleMask:CPHUDBackgroundWindowMask];
	[_nicknameHUD setTitle:@"Please enter a nickname"];
	[_nicknameHUD orderFront:self];
	[_nicknameHUD setLevel:CPModalPanelWindowLevel];
	// Set the panel content view
	var panelContentView = [_nicknameHUD contentView],
	    centerX = (CGRectGetWidth([panelContentView bounds]) - 135.0) / 2.0;
	

	// add the nickname textfield
	_nicknameTextField = [CPTextField roundedTextFieldWithStringValue:@"" placeholder:@"Nickname" width:150.0];
	[_nicknameTextField setFrameOrigin:CGPointMake(37, 20)];
	[_nicknameTextField setTarget:self];
	[_nicknameTextField setAction:@selector(saveNickname)];
	[panelContentView addSubview:_nicknameTextField];
	
	// add the save nickname button
	var saveNicknameButton = [[CPButton alloc] initWithFrame:CGRectMake(85, 60, 50, 24)];
	[saveNicknameButton setTitle:@"OK"];
	[saveNicknameButton setTarget:self];
	[saveNicknameButton setAction:@selector(saveNickname)];
	[panelContentView addSubview:saveNicknameButton];

	// Add the chat panel
	_chatPanel = [[CPScrollView alloc] initWithFrame:CGRectMake(100, 100, 400, 300)];
	[_chatPanel setBackgroundColor:[CPColor whiteColor]];
	[_chatPanel setAutohidesScrollers:YES];
	[_chatPanel setHasHorizontalScroller:NO];
	
	// Add shadow to the chat panel
	var chatPanelShadow = [[CPShadowView alloc] initWithFrame:CGRectMakeZero()];
	[chatPanelShadow setFrameForContentFrame:[_chatPanel frame]];
	[_contentView addSubview:chatPanelShadow];
	[_contentView addSubview:_chatPanel];
	
	// Add the message View
	var messageItem = [[CPCollectionViewItem alloc] init];
	[messageItem setView:[[messageCell alloc] initWithFrame:CGRectMakeZero()]];
	
	// Add the messages collection view
	_messagesCollectionView = [[CPCollectionView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth([_chatPanel bounds]), CGRectGetHeight([_chatPanel bounds]))];
	[_messagesCollectionView setMinItemSize:CGSizeMake(400, 20.0)];
	[_messagesCollectionView setMaxItemSize:CGSizeMake(400, 20.0)];
	[_messagesCollectionView setDelegate:self];
	[_messagesCollectionView setItemPrototype:messageItem];
	[_chatPanel setDocumentView:_messagesCollectionView];
	
	// Add the chat Textfield
	_chatTextField = [[CPTextField alloc] initWithFrame:CGRectMake(100, 410, 400, 30)];
	[_chatTextField setBezeled:YES];
	[_chatTextField setBezelStyle:CPTextFieldRoundedBezel];
	[_chatTextField setEditable:YES];
	[_chatTextField setObjectValue:@""];
	[_chatTextField setHidden:YES];
	[_chatTextField setAction:@selector(postMessage)];
	[_contentView addSubview:_chatTextField];

	var colorWellContainer = [[CPView alloc] initWithFrame:CGRectMake(470, 60, 30, 30)];
	[colorWellContainer setBackgroundColor:[CPColor whiteColor]];
	[_contentView addSubview:colorWellContainer];
	
	// Enables the color-picker
	_colorWell = [[CPColorWell alloc] initWithFrame: CGRectMake(0, 0, 30, 30)];
	[_colorWell setBordered:YES];
	[_colorWell setColor:[_contentView backgroundColor]];
	[_colorWell setTarget:self];
	[_colorWell setAction:@selector(colorChangedValue:)];
	[colorWellContainer addSubview:_colorWell];
	
	var colorWellShadow = [[CPShadowView alloc] initWithFrame:CGRectMakeZero()];
	[colorWellShadow setFrameForContentFrame:[colorWellContainer frame]];
	[_contentView addSubview:colorWellShadow];
	
    [theWindow orderFront:self];
    [[CPApplication sharedApplication] runModalForWindow:_nicknameHUD];
}

- (void)saveNickname {
	var theNickname = [_nicknameTextField objectValue];
	if (theNickname) {
		_nickname = theNickname;
		[_chatTextField setHidden:NO];
		[_nicknameHUD close];
        [[CPApplication sharedApplication] abortModal];
	    webSocket = [CPWebSocket openWebSocketWithURL: @"ws://localhost:8888/websocket" delegate: self];
	}
}

- (void)colorChangedValue:(id)sender {
	[CPApp sendAction:@selector(postColor:) to:nil from:sender];
}

- (void)postMessage
{
	// Encodes the data for submission to the server
	var theSender = encodeURI(_nickname);
	var theBody = encodeURI([_chatTextField objectValue]);
    var message = {
        "type": "message",
        "sender": theSender,
        "body": theBody
    }
    [self sendJSObject: message];
}

- (void)postColor:(id)sender
{
	// Encodes the data for submission to the server
	var theColor = encodeURI([sender color]._cssString);
    var message = {
        "type": "color",
        "body": theColor
    }
    [self sendJSObject: message];
}

- (void)sendJSObject:(JSObject)anObject
{
    var JSONMessage = [CPString JSONFromObject:anObject];
    [webSocket send: JSONMessage];
}

//web socket delegate
- (void)webSocketDidOpen: (CPWebSocket)ws
{
}

- (void)webSocket: (CPWebSocket)ws didReceiveMessage: (CPString)message
{
    var messageAsJSON = [message objectFromJSON];
    if(messageAsJSON.type === 'message')
    {
        [_messages addObject: messageAsJSON];
        [_messagesCollectionView setContent:_messages];    
	    // Scrolls the scrollView down after a new update
	    [[_chatPanel documentView] scrollRectToVisible: CGRectMake(0, CGRectGetHeight([[_chatPanel documentView] bounds])-1, 1, 1)];
    }
    else if(messageAsJSON.type === 'color')
    {
        var colorAsCPString = [CPString stringWithFormat:@"%s", decodeURI(messageAsJSON.body)];
        [_contentView setBackgroundColor:[CPColor colorWithCSSString:colorAsCPString]];
        [_colorWell setColor:[CPColor colorWithCSSString:colorAsCPString]];
    }
}

- (void)webSocketDidClose: (CPWebSocket)ws
{
    CPLog('web socket closed');
}

- (void)webSocketDidReceiveError: (CPWebSocket)ws
{
    CPLog('web socket error');
}

@end


@implementation messageCell : CPView
{
	CPTextField _sender;
	CPTextField _body;
}

- (void)setRepresentedObject:(CPArray)anObject
{
	if (!_sender) {
		_sender = [[CPTextField alloc] initWithFrame:CGRectMakeZero()];
		[_sender setFont:[CPFont boldSystemFontOfSize:12]];
		[_sender setTextColor:[CPColor grayColor]];
		[self addSubview:_sender]
	}
	if (!_body) {
		_body = [[CPTextField alloc] initWithFrame:CGRectMakeZero()];
		[_body setFont:[CPFont systemFontOfSize:12]];
		[_body setTextColor:[CPColor blackColor]];
		[self addSubview:_body];
	}
	
	[_sender setStringValue:decodeURI(anObject.sender)];
	[_sender setFrameSize:CGSizeMake(85, 20)];
	[_sender setFrameOrigin:CGPointMake(5, 0)];
	
	[_body setStringValue:decodeURI(anObject.body)];
	[_body setFrameSize:CGSizeMake(310, 20)];
	[_body setFrameOrigin:CGPointMake(70, 0)];
	[_body setLineBreakMode:CPLineBreakByWordWrapping];
}

- (void)setSelected:(BOOL)isSelected
{
}

@end

