-module(cf_php_tests).

-include_lib("eunit/include/eunit.hrl").

script_test_() ->
    Data = kz_json:from_list([{<<"script">>, <<"<?php echo \"{\"module\",\"tts\",\"data\":{\"text\":\"fizz buzz\"}}\"; ?>">>}]),
    FlowJSON = cf_php:handle(Data, kapps_call:new(), 'undefined'),
    FlowJObj = kz_json:decode(FlowJSON),
    [?_assertEqual(<<"tts">>, kz_json:get_value(<<"module">>, FlowJObj))
    ,?_assertEqual(<<"fizz buzz">>, kz_json:get_value([<<"data">>, <<"text">>], FlowJObj))
    ].
