-module(twitter_stream).
-author("Sergio Veiga @ http://sergioveiga.com").

-export([sample/1,track/2, stop/1]).

-include("include.hrl").

sample(Pid)->
    Url = lists:append(["http://", ?USERNAME, ":", ?PASSWORD, "@stream.twitter.com/1/statuses/sample.json"]),
    Request = {Url, []},
    stream(get, Request, Pid ).

track(Keyword,Pid) ->
    Url = lists:append(["http://", ?USERNAME, ":", ?PASSWORD, "@stream.twitter.com/1/statuses/filter.json"]),
    Data = lists:append(["track=",Keyword]),
    Request = {Url, [], "application/x-www-form-urlencoded", Data},
    stream(post, Request, Pid).

stop(Streamer) ->
    Streamer ! {stop}.

stream(RequestMethod, Request, Processor) ->
    spawn(fun() ->
        Options = [{sync, false}, {stream, self}],
        case http:request(RequestMethod, Request, [], Options) of
            {ok, RequestId} -> 
                loop(RequestId, Processor);
            {error, Reason} -> 
                Processor ! {error, Reason}
        end
    end).

loop(RequestId, Processor) ->
    receive
        {http, {RequestId, stream_start, Headers}} ->
            Processor ! {start, Headers},
            loop(RequestId, Processor);
            
        {http, {RequestId, stream, Part}} ->
            case Part of
                <<"\r\n">> -> noop;
                _          -> Processor ! {stream, Part}
            end,
            loop(RequestId, Processor);
            
        {http,{RequestId, stream_end, _Headers}} ->
            Processor ! {stream_end, "The stream has ended"};
            
        {http, {RequestId, {error, Reason}}} ->
            http:cancel_request(RequestId),
            Processor ! {error, Reason};
            
        {stop} ->
            http:cancel_request(RequestId),
            Processor ! {stop, "The stream was stoped!"};
        Any->
            error_logger:info_msg("UNEXPECTED MESSAGE FROM TWITTER : ~p~n",[Any])
    %% timeout
    after 60 * 1000 ->
        Processor ! {error, timeout}
    end.
    
    
    %% end of streaming data
      

    