#!/bin/sh
cd `dirname $0`

echo Starting TwitterStream.
erl \
	-name twitter_stream@localhost \
	-pa ./ebin -pa ./include \
	-s make all \
	-eval "application:start(twitter_stream)"