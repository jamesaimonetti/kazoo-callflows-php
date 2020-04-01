%%%-----------------------------------------------------------------------------
%%% @copyright (C) 2011-2020, 2600Hz
%%% @doc
%%% @author Karl Anderson
%%%
%%% This Source Code Form is subject to the terms of the Mozilla Public
%%% License, v. 2.0. If a copy of the MPL was not distributed with this
%%% file, You can obtain one at https://mozilla.org/MPL/2.0/.
%%%
%%% @end
%%%-----------------------------------------------------------------------------
-module(cf_php).

-behaviour(gen_cf_action).

-include_lib("callflow/src/callflow.hrl").

-export([handle/2]).

-ifdef(TEST).
-export([handle/3]).
-endif.

%%------------------------------------------------------------------------------
%% @doc Entry point for this module, attempts to call an endpoint as defined
%% in the Data payload.  Returns continue if fails to connect or
%% stop when successful.
%% @end
%%------------------------------------------------------------------------------
-spec handle(kz_json:object(), kapps_call:call()) -> 'ok'.
handle(Data, Call) ->
    FlowJSON = handle(Data, Call, kz_doc:id(Data)),
    maybe_branch_flow(Call, FlowJSON).

maybe_branch_flow(Call, 'undefined') ->
    cf_exe:continue(Call);
maybe_branch_flow(Call, FlowJSON) ->
    case kzd_callflows:validate_flow(
           kzd_callflows:set_flow(kzd_callflows:new(), kz_json:decode(FlowJSON))
          )
    of
        {'error', _Errors} ->
            lager:info("failed to validate return JSON flow: ~s", [FlowJSON]),
            lager:info("errors: ~p", [_Errors]),
            cf_exe:continue(Call);
        {'ok', ValidCallflow} ->
            lager:info("branching to ~p", [kzd_callflows:flow(ValidCallflow)]),
            cf_exe:branch(kzd_callflows:flow(ValidCallflow), Call)
    end.

handle(Data, Call, 'undefined') ->
    Script = kz_json:get_ne_binary_value(<<"script">>, Data),

    process_script(Data, Call, Script);
handle(Data, Call, PHPId) ->
    {'ok', PHPDoc} = kz_datamgr:open_cache_doc(kapps_call:account_db(Call), PHPId),
    [Script] = kz_doc:attachments(PHPDoc),
    process_script(Data, Call, Script).

process_script(Data, Call, Script) ->
    {'ok', PHPContext} = ephp:context_new(),

    ReqParams = kzt_kazoo:req_params(Call),
    ReqData = kz_json:get_json_value(<<"script_data">>, Data, kz_json:new()),
    ephp:register_var(PHPContext, <<"Call">>, ReqParams),
    ephp:register_var(PHPContext, <<"Data">>, kz_json:to_proplist(ReqData)),

    process_script_result(PHPContext, ephp:eval(PHPContext, Script)).

process_script_result(_PHPContext, {'ok', FlowJSON}) -> FlowJSON;
process_script_result(PHPContext, Error) ->
    ?LOG_INFO("error: ~p", [Error]),
    _ = ephp_error:handle_error(PHPContext, Error),
    Output = ephp_context:get_output(PHPContext),

    ?LOG_INFO("ctx: ~p", [PHPContext]),
    ?LOG_INFO("fs: ~p", [ephp_func:get_functions(ephp_context:get_funcs(PHPContext))]),
    ?LOG_INFO("output: ~p", [Output]),
    'undefined'.
