%%
%% Copyright (c) 2012-2013, Jorge Garrido <zgbjgg@gmail.com>
%% All rights reserved.
%%
%% This Source Code Form is subject to the terms of the Mozilla Public
%% License, v. 2.0. If a copy of the MPL was not distributed with this
%% file, You can obtain one at http://mozilla.org/MPL/2.0/.
%%
-module(spike_agent).

-author('zgbjgg@gmail.com').

-behaviour(gen_server).

-include("spike.hrl").

%% API
-export([start_link/0, cs_node/0, stop/0]).

%% gen_server callbacks
-export([init/1, handle_call/3, handle_cast/2, handle_info/2,
	 terminate/2, code_change/3]).

-define(SERVER, ?MODULE). 

-record(state, { cs_node, timeout }).

%%%===================================================================
%%% API
%%%===================================================================

%%--------------------------------------------------------------------
%% @doc
%% Get cs node.
%%
%% @spec get_devices() -> list()
%% @end
%%--------------------------------------------------------------------
-spec cs_node() -> atom().
cs_node() ->
    gen_server:call(?MODULE, cs_node).

%%--------------------------------------------------------------------
%% @doc
%% Stops the gen server
%%
%% @spec stop() -> ok
%% @end
%%--------------------------------------------------------------------
-spec stop() -> ok.
stop() ->
    gen_server:call(?MODULE, stop).

%%--------------------------------------------------------------------
%% @doc
%% Starts the server
%%
%% @spec start_link() -> {ok, Pid} | ignore | {error, Error}
%% @end
%%--------------------------------------------------------------------
start_link() ->
    {ok, CS} = application:get_env(spike, cs_node),
    {ok, Timeout} = application:get_env(spike, timeout),
    gen_server:start_link({local, ?SERVER}, ?MODULE, [CS, Timeout], []).

%%%===================================================================
%%% gen_server callbacks
%%%===================================================================

%%--------------------------------------------------------------------
%% @private
%% @doc
%% Initiates the server
%%
%% @spec init(Args) -> {ok, State} |
%%                     {ok, State, Timeout} |
%%                     ignore |
%%                     {stop, Reason}
%% @end
%%--------------------------------------------------------------------
init([CS, Timeout]) ->
    process_flag(trap_exit, true),
    ok = net_kernel:monitor_nodes(true), 
    case net_adm:ping( CS ) of
        pong ->
            ?LOG_INFO("CS Node AGREE ~p \n", [CS]),
            {ok, #state{cs_node={pong, CS}, timeout=Timeout}, Timeout};
        _    ->
            ?LOG_INFO("CS Node UNREACHABLE ~p\n", [CS]),
            {ok, #state{cs_node={pang, CS}, timeout=Timeout}, Timeout}
    end.         

%%--------------------------------------------------------------------
%% @private
%% @doc
%% Handling call messages
%%
%% @spec handle_call(Request, From, State) ->
%%                                   {reply, Reply, State} |
%%                                   {reply, Reply, State, Timeout} |
%%                                   {noreply, State} |
%%                                   {noreply, State, Timeout} |
%%                                   {stop, Reason, Reply, State} |
%%                                   {stop, Reason, State}
%% @end
%%--------------------------------------------------------------------
handle_call(cs_node, _From, State=#state{cs_node=CS, timeout=Timeout}) ->
    {reply, {ok, CS}, State, Timeout};
handle_call(stop, _From, State=#state{cs_node=_CS, timeout=Timeout})   ->
    {stop, normal, ok, State, Timeout}.

%%--------------------------------------------------------------------
%% @private
%% @doc
%% Handling cast messages
%%
%% @spec handle_cast(Msg, State) -> {noreply, State} |
%%                                  {noreply, State, Timeout} |
%%                                  {stop, Reason, State}
%% @end
%%--------------------------------------------------------------------
handle_cast(_Msg, State) ->
    {noreply, State}.

%%--------------------------------------------------------------------
%% @private
%% @doc
%% Handling all non call/cast messages
%%
%% @spec handle_info(Info, State) -> {noreply, State} |
%%                                   {noreply, State, Timeout} |
%%                                   {stop, Reason, State}
%% @end
%%--------------------------------------------------------------------
handle_info(timeout, State=#state{cs_node={pong, _CS}, timeout=Timeout})    ->
    {noreply, State, Timeout};
handle_info(timeout, #state{cs_node={pang, CS}, timeout=Timeout})           ->
    Net = case net_adm:ping(CS) of                                                      
            pong ->                                                                       
                ?LOG_INFO("CS Node AGREE ~p \n", [CS]),                            
                {pong, CS};
	    _    ->                                                                       
                ?LOG_INFO("CS Node UNREACHABLE ~p\n", [CS]), 
		{pang, CS}                     
    end,
    {noreply, #state{cs_node=Net, timeout=Timeout}, Timeout};    
handle_info({nodedown, CS}, State=#state{cs_node={_, CS}, timeout=Timeout}) ->
    Net = case net_adm:ping(CS) of                                                       
        pong ->                                                                        
            ?LOG_INFO("CS Node AGREE ~p \n", [CS]),                             
            {pong, CS};
        _    ->                                                                        
            ?LOG_INFO("CS Node UNREACHABLE ~p\n", [CS]),                        
            {pang, CS}
    end,
    {noreply, State#state{cs_node=Net, timeout=Timeout}, Timeout};
handle_info({nodedown, _}, State=#state{cs_node=_CS, timeout=Timeout})      ->
    {noreply, State, Timeout};
handle_info({nodeup, _NodeUp}, State=#state{cs_node=_CS, timeout=Timeout})  ->
    {noreply, State, Timeout}.

%%--------------------------------------------------------------------
%% @private
%% @doc
%% This function is called by a gen_server when it is about to
%% terminate. It should be the opposite of Module:init/1 and do any
%% necessary cleaning up. When it returns, the gen_server terminates
%% with Reason. The return value is ignored.
%%
%% @spec terminate(Reason, State) -> void()
%% @end
%%--------------------------------------------------------------------
terminate(_Reason, _State) ->
    ok.

%%--------------------------------------------------------------------
%% @private
%% @doc
%% Convert process state when code is changed
%%
%% @spec code_change(OldVsn, State, Extra) -> {ok, NewState}
%% @end
%%--------------------------------------------------------------------
code_change(_OldVsn, State, _Extra) ->
    {ok, State}.

%%%===================================================================
%%% Internal functions
%%%===================================================================
