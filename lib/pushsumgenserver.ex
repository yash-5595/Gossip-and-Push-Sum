defmodule PushSum do
    use GenServer

    def start(nodeid, neighbour,failnodes) do
        GenServer.start_link(__MODULE__, [nodeid, neighbour, failnodes], name: {:via, Registry, {:storenodepids, nodeid}})
    end


    # def init([nodeid, neighbour, failnodes]) do
    #     if length(neighbour) != 0 do
    #         receive do


    #             {:sumreceived, s,w} -> sumspread = Task.start(fn -> pushsumtoneighbour(neighbour, s + nodeid, w+1, nodeid) end)
    #             IO.puts "recieved first gossip for, #{nodeid} "
    #             PushSum.receivesum(1, s + nodeid,w+1,sumspread, nodeid, nodeid)


    #         end
    #     end
    #     {:ok, nodeid}
    # end



    def init([nodeid,neighbour, failnodes]) do
        flagfailed = nodeid not in failnodes

        flagnoneighbours = length(neighbour) != 0
        IO.puts  "failed flag, #{flagfailed and flagnoneighbours}, #{nodeid}"
        if (flagfailed and flagnoneighbours)  do
          # IO.puts "length of neighbours, #{length(neighbour)}"

          receive do
            {:sumreceived, s,w} -> sumspread = Task.start(fn -> pushsumtoneighbour(neighbour, s + nodeid, w+1, nodeid) end)
            IO.puts "recieved first gossip for, #{nodeid} "
            PushSum.receivesum(1, s + nodeid,w+1,sumspread, nodeid, nodeid)
          end
        else
          receive do
            {_, gossipmessage} -> IO.puts "I have no neighbours, #{nodeid}"
            Registry.unregister(:storenodepids, nodeid)
            send(:global.whereis_name(:gossipsupervise), {:nodeconverged, nodeid})
            Process.exit(GossipGenserver.getpidofnode(nodeid), :kill)



          end
        end
        {:ok, nodeid}
      end

    def checkratio(oldratio,updtdratio) do

        diff = abs(updtdratio - oldratio)
        if(diff> :math.pow(10,-10)) do
            0
        else
            1
        end
    end

    def receivesum(convergeratio, s,w,sumspread, oldratio, nodeid) do
        # received
        # IO.puts "white iverson"
        {_sometmp, nodeprocesspid} = sumspread
        updtdratio = s/w
        delta = abs(updtdratio - oldratio)
        convergeratio = if delta > :math.pow(10,-10), do: 0, else: convergeratio + 1
        # if(checkratio(oldratio, updtdratio) !=1) do
        #     convergeratio = 0
        # else
        #     convergeratio = convergeratio + 1
        # end
        # IO.puts "Convergence, #{convergeratio}"
        if(convergeratio >= 3) do
            # IO.puts "INside Convergence"
            Process.exit(nodeprocesspid, :kill)
            # send to supervisor that node converged
            send(:global.whereis_name(:gossipsupervise), {:nodeconverged, nodeid})

            Process.exit(self(), :kill)
        else
            s = s/2
            w = w/2
            send(nodeprocesspid,{:nodechanged, s,w})
            receive do
                {:sumreceived, sr,wr} -> receivesum(convergeratio, s+sr, w+wr, sumspread, updtdratio, nodeid)
            after
                100 -> receivesum(convergeratio, s, w, sumspread, updtdratio, nodeid)
            end
        end
    end

    def pushsumtoneighbour(neighbour,s,w,nodeid) do

            # IO.puts "a lot, #{neighbour}, #{nodeid}, #{w}"
            try do

                {s,w} = receive do
                            {:nodechanged, sr1, wr1} -> {sr1,wr1}
                        end
                randneighbour = Enum.random(neighbour)

                neighbourpid = GossipGenserver.getpidofnode(randneighbour)
                # IO.puts "neighbour, #{randneighbour}"
                # IO.inspect(neighbourpid)
                if neighbourpid != nil do
                    # IO.puts "inside if of sending to neighbour, #{randneighbour}"
                    send(neighbourpid, {:sumreceived, s,w})
                 end
                 pushsumtoneighbour(neighbour, s, w, nodeid)

            rescue
                    _ ->  pushsumtoneighbour(neighbour,s, w, nodeid)
            end


    end


end
