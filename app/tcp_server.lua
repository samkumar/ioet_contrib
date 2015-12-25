require "storm"
require "cord"

-- Create server socket
lstnsock = storm.net.tcppassivesocket()

-- Bind socket to port 32067
storm.net.tcpbind(lstnsock, 32067)

-- No call to listen() is needed
cord.new(function ()
    while true do
        clntsock = cord.await(storm.net.tcplistenaccept, lstnsock)
        cord.new(function () server(clntsock) end)
    end
end)

-- Function to perform interaction with client
function server(csock)
    cord.await(storm.net.tcpaddconnectdone, csock)
    cord.await(storm.net.tcpsendfull, csock, long_string)
    storm.net.tcpshutdown(csock, storm.net.SHUT_RDWR)
    how = cord.await(storm.net.tcpaddconnectionlost, csock)
    print("Connection ended. Reason: " .. how)
    storm.net.tcpclose(csock)
end

long_string = "The Transmission Control Protocol (TCP) is a core protocol of the Internet protocol suite. It originated in the initial network implementation in which it complemented the Internet Protocol (IP). Therefore, the entire suite is commonly referred to as TCP/IP. TCP provides reliable, ordered, and error-checked delivery of a stream of octets between applications running on hosts communicating over an IP network. TCP is the protocol that major Internet applications such as the World Wide Web, email, remote administration and file transfer rely on. Applications that do not require reliable data stream service may use the User Datagram Protocol (UDP), which provides a connectionless datagram service that emphasizes reduced latency over reliability."

cord.enter_loop()
