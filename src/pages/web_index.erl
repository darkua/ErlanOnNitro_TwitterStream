-module (web_index).
-author("Sergio Veiga @ http://sergioveiga.com").
-include_lib ("nitrogen/include/wf.inc").

-include("include.hrl").

-compile(export_all).

main() -> 
	#template { file="index.html"}.

title() ->
	"Erlang On Nitro".