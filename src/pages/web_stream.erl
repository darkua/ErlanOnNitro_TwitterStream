-module (web_stream).
-author("Sergio Veiga @ http://sergioveiga.com").
-include_lib ("nitrogen/include/wf.inc").

-include("include.hrl").

-compile(export_all).

main() -> 
	#template { file="template.html"}.

title() ->
	"Twitter Stream powered by Erlang On Nitro".

body() ->
	
	%%builds the stream
	Stream = start_stream(),
	
	%% the html to render
	Body= [
	    #panel{class="header", body=[
    	    #h1{text="Erlang on Nitro - Twitter Stream"},
    	    #panel{id=feedback,class="feedback", body=[
    	        "Calling Twitter..."
    	    ]},
    	    #panel{id=control,body=[#button{text="Stop", postback={stop,Stream}}]}
    	]},
    	#panel{id=stream,body=[]}
	],
	
	wf:render(Body).
	

start_stream()->
    %% create your comet function, and 
	Pid = wf:comet(fun()-> web_index:loop() end),
	
	%%check for track
	case wf:get_path_info() of
	    []->
	        twitter_stream:sample(Pid);
	    Track->
	        twitter_stream:track(Track,Pid)
	end.

loop()->
    receive
        {start,_Message}->
            wf:update(feedback,"Stream Running...");
        {stream,Message}->
    	    get_tweet_info(Message);
    	{stream_end,_Message}->
    	    restart_button(),
    	    wf:update(feedback,"Stream Ended...");
    	{stop,_Reason}->
    	    restart_button(),
            wf:update(feedback,"Stream Stoped...");
    	{error,Reason}->
    	    error_logger:error_msg("Error : ~p~n",[Reason]),
    	    restart_button(),
            wf:update(feedback,#panel{class="error",body=wf:f("Error : ~s !",[Reason])});
    	Any->
            error_logger:info_msg("ANY : ~p~n",[Any])
    	after 55000 ->
    	    wf:update(feedback,"to quiet for me...")
    	end,
    wf:comet_flush(),
	web_index:loop().

get_tweet_info(Message)->
    
    %%decode from json to erlang proplist structure
    case utils:json_decode(Message) of
        {ok,Tweet}->
            %%tweet comes in binary, so we need to cleanup first
            TweetPropList =  utils:cleanup_bin(Tweet),
            
            io:format("~p~n",[TweetPropList]),
            
            %%get tweet info id and text
            TweetRecord = #tweet{id=proplists:get_value("id",TweetPropList),text=proplists:get_value("text",TweetPropList)},
            
            %%username and profilepicture is inside other user object, so we need to first get user
            User = proplists:get_value("user",TweetPropList),
            
            
            case User of 
                undefined ->
                    %% this is an delete message
                    error_logger:info_msg("Twitter error sent user undefined : ~p~n",[TweetPropList]);
                _->
                    %%now we can "update" the record we already created, by copying its properties to the new one
                    NewTweetRecord = TweetRecord#tweet{screen_name=proplists:get_value("screen_name",User),picture=proplists:get_value("profile_image_url",User)},
            
                    add_tweet(NewTweetRecord)
            end;
            
        {error,Error}->
            %%show the error
            error_logger:error_msg("ERROR : ~p : ~p ~n",[Message,Error]),
            wf:update(feedback,#panel{class="error",body=["Error with json!"]})
    end.    

add_tweet(Tweet)->
    wf:insert_top(stream,build_tweet(Tweet)).

%% build a tweet
build_tweet(Tweet) when is_record(Tweet,tweet) ->
    #panel{id=Tweet#tweet.id, class="tweet clearfix", body=[
            #image{image=Tweet#tweet.picture},
            #panel{class="content", body=[
                #link{url="http://twitter.com/"++Tweet#tweet.screen_name,text=Tweet#tweet.screen_name},
                Tweet#tweet.text
            ]}
        ]}.


restart_button()->
    wf:update(control,#button{text="Restart", postback={restart}}).

%% events
event({stop,Stream})->
    twitter_stream:stop(Stream);

event({restart})->
    Stream = start_stream(),
    wf:update(control,#button{text="Stop", postback={stop,Stream}}),
    wf:update(feedback,"Calling Twitter...");

event(_) -> ok.


drop_event(DragTag, DropTag) ->
  Message = wf:f("Dropped ~p on ~p", [DragTag, DropTag]),
  io:format("~p~n",[Message]),
  ok.

    