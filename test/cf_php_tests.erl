-module(cf_php_tests).

-include_lib("eunit/include/eunit.hrl").

script_test_() ->
    application:ensure_all_started(ephp),

    {'ok', CWD} = file:get_cwd(),
    File = filename:join([CWD, "test", "script.php"]),

    {'ok', PHPScript} = file:read_file(File),
    Data = kz_json:from_list([{<<"script">>, PHPScript}]),
    FlowJSON = cf_php:handle(Data, kapps_call:new(), 'undefined'),
    FlowJObj = kz_json:decode(FlowJSON),
    [?_assertEqual(<<"tts">>, kz_json:get_value(<<"module">>, FlowJObj))
    ,?_assertEqual(<<"fizz buzz">>, kz_json:get_value([<<"data">>, <<"text">>], FlowJObj))
    ].
