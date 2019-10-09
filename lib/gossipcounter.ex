defmodule GossipCounter do

    def startspreadinggossip(numnodes, algorithm, topology) do
        # start task
        IO.puts "started spreading gossip"
        startTime = System.system_time(:millisecond)
        monitorconvergence = Task.async(fn-> GossipCounter.checkforconvergence(numnodes) end)
        :global.register_name(:gossipsupervise,monitorconvergence.pid)
        # select a random node and start pass first message
        nodeidselected = Enum.random(1..numnodes)
        IO.puts "node selected, #{nodeidselected}"
        firstnode = GossipGenserver.getpidofnode(nodeidselected)
        # IO.inspect(GossipGenserver.getpidofnode(1))
        # firsttemp = GossipGenserver.getpidofnode(1)
        # Process.exit(firstsemp, :kill)
        send(firstnode, {:gotrumor, "I never say anything"})
        IO.puts "selected first node, #{nodeidselected}"
        Task.await(monitorconvergence, :infinity)
        timeDifference = System.system_time(:millisecond) - startTime
        IO.puts "Time taken for convergence: #{timeDifference} milliseconds"
    end

    def checkforconvergence(nodesremaining) do
        if(nodesremaining > 0) do
            receive do
                {:nodeconverged, nodeid} ->
                IO.puts "Nodes  converged, #{nodeid}"
                checkforconvergence(nodesremaining-1)
            end
        else
            nil
        end
    end


    def startspreadingpushsum(numnodes, algorithm, topology) do
    # start task
    IO.puts "started spreading pushsum"
    startTime = System.system_time(:millisecond)
    monitorconvergence = Task.async(fn-> GossipCounter.checkforconvergence(numnodes) end)
    :global.register_name(:gossipsupervise,monitorconvergence.pid)
    # select a random node and start pass first message
    nodeidselected = Enum.random(1..numnodes)
    firstnode = GossipGenserver.getpidofnode(nodeidselected)
    send(firstnode, {:sumreceived, 0,0})
    IO.puts "selected first node, #{nodeidselected}"
    Task.await(monitorconvergence, :infinity)
    timeDifference = System.system_time(:millisecond) - startTime
    IO.puts "Time taken for convergence: #{timeDifference} milliseconds"
end

    # check for convergence of each node
end
