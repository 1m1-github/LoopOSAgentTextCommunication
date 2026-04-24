module LoopOSAgentTextCommunication

using ZMQ
using LoopOS: InputPeripheral, OutputPeripheral, listen, @whiletrue

const DEALERSOCKET = Ref{Socket}()
const SUBSOCKET = Ref{Socket}()

function init(group, routerlocation, publocation)
    DEALERSOCKET[] = Socket(DEALER)
    setproperty!(DEALERSOCKET[], :routing_id, Sys.username())
    SUBSOCKET[] = Socket(SUB)
    connect(DEALERSOCKET[], routerlocation)
    connect(SUBSOCKET[], publocation)
    subscribe(SUBSOCKET[], group)
    subscribe(SUBSOCKET[], "∀")
    listen(RECEIVEMESSAGE)
    @async @whiletrue receive(DEALERSOCKET[]), @async @whiletrue receive(SUBSOCKET[])
end

function receive(socket)
    frames = ZMQ.recv_multipart(socket)
    to = String(frames[1])
    from = String(frames[2])
    message = String(frames[3])
    put!(RECEIVEMESSAGE, "$from>$to>$message")
end

import Base: take!, put!
send(message, to) = ZMQ.send_multipart(DEALERSOCKET[], [to, getproperty(DEALERSOCKET[], :routing_id), message])
struct DirectMessage <: OutputPeripheral end
put!(::DirectMessage, message::String, to::String="Dona") = send(message, to)
struct GroupMessage <: OutputPeripheral end
put!(::GroupMessage, message::String) = send(message, "group")
struct ReceiveMessage <: InputPeripheral
    channel::Channel{String}
end
take!(a::ReceiveMessage) = take!(a.channel)
put!(a::ReceiveMessage, message) = put!(a.channel, message)
const RECEIVEMESSAGE = ReceiveMessage(Channel{String}(Inf))

end
