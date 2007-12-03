-module(openmoko_addressbook).
-behaviour(gen_server).

-include("openmoko.hrl").
-include("openmoko_addressbook.hrl").

-export([start_link/0, start_link/1]).
-export([list/0, lookup/1, update/1, delete_by_name/1, delete_record/1]).
-export([init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2, code_change/3]).

-define(TABLE_NAME, openmoko_addressbook).

%---------------------------------------------------------------------------
%% Interface

start_link() ->
    {ok, AddressbookFile} = application:get_env(addressbook_file),
    start_link(AddressbookFile).

start_link(AddressbookFile) ->
    gen_server:start_link({local, ?MODULE}, ?MODULE, [AddressbookFile], []).

list() ->
    gen_server:call(?MODULE, list).

lookup(Name) ->
    gen_server:call(?MODULE, {lookup, Name}).

update(Record) ->
    gen_server:call(?MODULE, {update, Record}).

delete_by_name(Name) ->
    gen_server:call(?MODULE, {delete_by_name, Name}).

delete_record(Record) ->
    gen_server:call(?MODULE, {delete_record, Record}).

%---------------------------------------------------------------------------
%% gen_server behaviour

init([AddressbookFile]) ->
    {ok, _Name} = dets:open_file(?TABLE_NAME, [{file, AddressbookFile},
					       {keypos, 2}]),
    {ok, nostate}.

handle_call(list, _From, State) ->
    List = dets:foldl(fun (Record, Acc) -> [Record | Acc] end, [], ?TABLE_NAME),
    {reply, lists:sort(List), State};
handle_call({lookup, Name}, _From, State) ->
    Result = case dets:lookup(?TABLE_NAME, Name) of
		 [] -> {error, not_found};
		 [Record] -> {ok, Record}
	     end,
    {reply, Result, State};
handle_call({update, Record}, _From, State) ->
    ok = dets:insert(?TABLE_NAME, Record),
    {reply, ok, State};
handle_call({delete_by_name, Name}, _From, State) ->
    ok = dets:delete(?TABLE_NAME, Name),
    {reply, ok, State};
handle_call({delete_record, Record}, _From, State) ->
    ok = dets:delete_object(?TABLE_NAME, Record),
    {reply, ok, State};
handle_call(_Request, _From, State) ->
    {reply, not_understood, State}.

handle_cast(Message, State) ->
    error_logger:info_msg("Unknown openmoko_addressbook:handle_cast ~p~n", [Message]),
    {noreply, State}.

handle_info(Message, State) ->
    error_logger:info_msg("Unknown openmoko_addressbook:handle_info ~p~n", [Message]),
    {noreply, State}.

terminate(_Reason, _State) ->
    ok = dets:close(?TABLE_NAME),
    ok.

code_change(_OldVsn, State, _Extra) ->
    {ok, State}.