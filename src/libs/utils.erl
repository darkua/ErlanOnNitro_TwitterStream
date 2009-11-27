-module(utils).

-export([
    cleanup_bin/1,
    json_decode/1
]).

%%atom suport
cleanup_bin(Atom) when is_atom(Atom)->
    Atom;
    
%%binary support
cleanup_bin(Bin) when is_binary(Bin)->
    binary_to_list(Bin);

%% @doc converts all binary key and values on a proplist to lists.
%% WARNING: This function only support list of binaries as input.
cleanup_bin(Bin) when is_list(Bin) ->
    [bin_to_list(X,X) || X <- Bin].

%% @doc binary_to_list/2 but if the input is not binary returns the 'Default' value.
%% WARNING: This function only support binaries, tuple and list of binaries as input.
bin_to_list(Bin, _Default) when is_binary(Bin) -> binary_to_list(Bin);
bin_to_list(Bin, _Default) when is_integer(Bin) -> integer_to_list(Bin);
bin_to_list(Bin, _Default) when is_list(Bin) -> cleanup_bin(Bin);
bin_to_list({struct, Obj}, _Default) -> cleanup_bin(Obj);
bin_to_list(Bin, _Default) when is_tuple(Bin) -> list_to_tuple(cleanup_bin(tuple_to_list(Bin)));
bin_to_list(_Bin, Default) -> Default.


%%decode from json to erlang lists
json_decode(Body) ->
    try mochijson2:decode(Body) of
        {struct, Json} ->
            {ok, Json};
        Json->
            io:format("~p~n",["M"]),
            {ok, Json}
    catch
        _:Error ->
            error_logger:error_msg("You have tried to decode something that is not json : ~p~n",[Error]),
            {error, "Failed parsing json"}
    end
.
