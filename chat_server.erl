-module(chat_server).
-export([listen/1]).

-define(TCP_OPTIONS, [binary, {active, false}]).

listen(Port) ->
    {ok, LSocket} = gen_tcp:listen(Port, ?TCP_OPTIONS),
    ets:new(rooms,[bag,named_table]),
    accept(LSocket).

accept(LSocket) ->
    {ok, Socket} = gen_tcp:accept(LSocket),
    ets:insert(rooms,{users,Socket}),
    io:format("Client connected~n"),
    spawn(fun() -> loop(Socket) end),
    %%spawn(chat_server,loop,[Socket]),
    accept(LSocket).

loop(Socket) ->
    case gen_tcp:recv(Socket, 0) of
        {ok, Message} ->
            io:format("~s~n",[Message]),
            send_to_all(filter_users(ets:lookup(rooms,users),Socket),Message),
            loop(Socket);
        {error, closed} ->
            ets:delete_object(rooms,{users,Socket}),
            io:format("Client disconnected~n")
    end.

filter_users(Users,Socket) ->
    lists:delete({users,Socket},Users).

send_to_all([],Message) ->
    {ok,Message};
send_to_all(Users,Message) ->
    [First|Rest] = Users,
    {users,FirstSocket} = First, 
    gen_tcp:send(FirstSocket,Message),
    send_to_all(Rest,Message).