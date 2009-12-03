-module (web_cloud).
-author("Sergio Veiga @ http://sergioveiga.com").
-include_lib ("nitrogen/include/wf.inc").

-include("include.hrl").

-compile(export_all).

main() -> 
	#template { file="cloud.html"}.

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
    	        "Calling Twitter...pls wait..."
    	    ]},
    	    #panel{id=control,body=[#button{text="Stop", actions=#event{actions="$.growl('','Stream is Stoping...');"}, postback={stop,Stream}}]}
    	]}
	],
	
	wf:render(Body).
	

start_stream()->
    %% create your comet function, and 
	Pid = wf:comet(fun()-> ?MODULE:loop() end),
	
	%%check for track
	case wf:get_path_info() of
	    []->
	        twitter_stream:sample(Pid);
	    Track->
	        twitter_stream:track(Track,Pid)
	end.
    
loop()->
    receive
        {unauthorized,Message}->
            io:format("~p~n",[Message]),
            wf:update(feedback,"Your twitter credentials are wrong, check include.htr file!");
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
	?MODULE:loop().

get_tweet_info(Message)->
    
    %%decode from json to erlang proplist structure
    case utils:json_decode(Message) of
        {ok,Tweet}->
            %%tweet comes in binary, so we need to cleanup first
            TweetPropList =  utils:cleanup_bin(Tweet),
            
            %%get tweet info id and text
            TweetRecord = #tweet{id=proplists:get_value("id",TweetPropList),text=proplists:get_value("text",TweetPropList)},
            
            %%username and profilepicture is inside other user object, so we need to first get user
            User = proplists:get_value("user",TweetPropList),
            
            
            case User of 
                undefined ->
                    %% this is an delete message
                    error_logger:info_msg("Twitter error sent user undefined : ~p~n",[TweetPropList]);
                _->
                    %% diff between number of followers and following
                    Ratio =  list_to_integer(proplists:get_value("followers_count",User)) - list_to_integer(proplists:get_value("friends_count",User)),
                    
                    %%now we can "update" the record we already created, by copying its properties to the new one
                    NewTweetRecord = TweetRecord#tweet{screen_name=proplists:get_value("screen_name",User),picture=proplists:get_value("profile_image_url",User),size=calculate_size(Ratio)},
                    
                    add_tweet(NewTweetRecord)
            end;
            
        {error,Error}->
            %%show the error
            error_logger:error_msg("ERROR : ~p : ~p ~n",[Message,Error]),
            wf:update(feedback,#panel{class="error",body=["Error with json!"]})
    end.    

%% number of folowers less then following :(
calculate_size(Ratio)  when Ratio < 0 ->
    24;
%% number of folowers equal to following :(
calculate_size(Ratio)  when Ratio == 0 ->
    24;
%% number of folowers superior, so lets assume the max size bigger is 24, we give it to people having more then 1000 diff
calculate_size(Ratio)  when Ratio > 0 ->
    Size = ((Ratio * 24) div 1000),
    case Size rem 24 of
        X when X =:= Size ->
            24+X;
        _ ->
            48
    end.

add_tweet(Tweet)->
    %%sending the info to js, so it can build the tweet
    wf:wire(wf:f("buildTweet({id:'~s',screen_name:'~s',picture:'~s',text:\"~s\",size:'~p'})",[
                    Tweet#tweet.id,Tweet#tweet.screen_name,Tweet#tweet.picture,wf_utils:js_escape(Tweet#tweet.text),Tweet#tweet.size])
    ).

restart_button()->
    wf:update(control,#button{text="Restart", actions=#event{actions="$.growl('','Stream is Restaring...');"},postback={restart}}).
    

%% events
event({stop,Stream})->
    twitter_stream:stop(Stream);

event({restart})->
    Stream = start_stream(),
    wf:update(control,#button{text="Stop", actions=#event{actions="$.growl('','Stream is Stoping...');"}, postback={stop,Stream}}),
    wf:update(feedback,"Calling Twitter...pls wait...");

event(_) -> ok.

    