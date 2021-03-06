-module(simple_echo_server).

-export([start/1]).
-export([loop_echo_server/1]).

-define(x(X), begin
                  fun() ->
                     __YY__ = X,
                     pretty_print(?MODULE, ?LINE, ??X, __YY__),
                     __YY__
                  end()
              end).

pretty_print(_M, L, S, V) ->
    io:format("[~10s]~-30s = ~p~n", [integer_to_list(L), S, V]).

start(Port) ->
    multi_threaded_echo_server(Port).

%%------------------------------------------------------------------------------
%% multi threaded tcp echo server
%%------------------------------------------------------------------------------
multi_threaded_echo_server(Port) ->
    {ok, ListenSocket} = gen_tcp:listen(Port, [{reuseaddr, true}]),
    ?x(self()),
    ?x(ListenSocket),
    do_listen_loop(ListenSocket).

%% Whenever a new connection, spawn a new worker to handle this connection
do_listen_loop(Socket) ->
    io:format("== ~p listening on ~p~n", [self(), Socket]),
    {ok, ConnSocket} = gen_tcp:accept(Socket),
    ?x(ConnSocket),
    EchoWorker= spawn(?MODULE, loop_echo_server, [ConnSocket]),
    ?x(EchoWorker),
    gen_tcp:controlling_process(ConnSocket, EchoWorker),
    do_listen_loop(Socket).

loop_echo_server(Socket) ->
    receive
        {tcp, Socket, Bin} ->
            io:format("~p got message through ~p~n~s~n", [self(), Socket, Bin]),
            gen_tcp:send(Socket, [pid_to_list(self()), " received: ", Bin]),
            loop_echo_server(Socket);
        {tcp_closed, Socket} ->
            io:format("== Closed from client side ==~n"),
            ok
    end.
