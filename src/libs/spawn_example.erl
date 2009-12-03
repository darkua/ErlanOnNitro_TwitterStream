-module(spawn_example).

-export([
    start/0,
    loop/0
]).

start()->
    Pid = spawn(fun()->loop() end),
    register(bot,Pid).
    
loop()->
    receive
        hello ->
            io:format("Hello. How are you?~n",[]);
        _->
            void
    end.