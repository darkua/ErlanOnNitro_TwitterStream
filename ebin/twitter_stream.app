{application, twitter_stream, [
	{description,  "Nitrogen Website"},
	{mod, {twitter_stream_app, []}},
	{env, [
		{platform, inets}, %% {inets|yaws|mochiweb}
		{port, 8000},
		{session_timeout, 20},
		{sign_key, "SIGN_KEY"},
		{wwwroot, "./wwwroot"},
		{templateroot, "./wwwroot/templates/"}
	]}
]}.