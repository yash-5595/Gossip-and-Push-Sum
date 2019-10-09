defmodule GossipGenserver do
  use GenServer

  def start(nodeid, neighbour, failnodes) do
    # IO.puts "gossip first start called"
    GenServer.start_link(__MODULE__, [nodeid, neighbour, failnodes], name: {:via, Registry, {:storenodepids, nodeid}})
  end

def getpidofnode(nodeid) do
  case Registry.lookup(:storenodepids, nodeid) do
  [{pid, _}] -> pid
  [] -> nil
  end
end

  # For the first gossip to recieve and then start spreading gossip
  def init([nodeid,neighbour, failnodes]) do
    flagfailed = nodeid not in failnodes

    flagnoneighbours = length(neighbour) != 0
    # IO.puts  "failed flag, #{flagfailed and flagnoneighbours}, #{nodeid}"
    if (flagfailed and flagnoneighbours)  do
      # IO.puts "length of neighbours, #{length(neighbour)}"

      receive do
        {_, gossipmessage} -> rumorspread = Task.start(fn -> passgossiptoneighbor(neighbour, gossipmessage, nodeid) end)
        # IO.puts "recieved first gossip for, #{nodeid} "
        GossipGenserver.recievenode(1, gossipmessage,rumorspread,nodeid)
        #IO.puts "recieved first gossip for, #{nodeid} "
      end
    else
      receive do
        {_, gossipmessage} -> IO.puts "I have no neighbours, #{nodeid}"
        Registry.unregister(:storenodepids, nodeid)
        send(:global.whereis_name(:gossipsupervise), {:nodeconverged, nodeid})
        Process.exit(getpidofnode(nodeid), :kill)



      end
    end
    {:ok, nodeid}
  end

 # randomly select a neighbour and pass gossipmessage in loop
  def passgossiptoneighbor(neighbour, gossipmessage, nodeid) do
    # IO.puts "a lot, #{neighbour}, #{nodeid}, #{gossipmessage}"
    randneighbour = Enum.random(neighbour)

    neighbourpid = GossipGenserver.getpidofnode(randneighbour)
    if neighbourpid != nil  do
      send(neighbourpid, {:gotrumor, gossipmessage})
    end
    Process.sleep(100)
    passgossiptoneighbor(neighbour, gossipmessage, nodeid)
  end

  # recursively waiting to recieve gossipmessage until the node heard it 10 times

  def recievenode(countrecieved, gossipmessage, rumorspread, nodeid) do
    # sIO.puts "white iverson, #{nodeid}, #{countrecieved}"
    {_sometmp, nodeprocesspid} = rumorspread
    if(countrecieved<10) do
      receive do

        {:gotrumor, gossipmessage} -> recievenode(countrecieved+1, gossipmessage, rumorspread, nodeid)

      end
    else
      # IO.puts "got to else condition of convergence"
      # tell its supervisor that this node converged
      send(:global.whereis_name(:gossipsupervise), {:nodeconverged, nodeid})

      # IO.inspect(nodeprocesspid)
      # IO.inspect(getpidofnode(nodeid))
      # IO.puts Process.alive?(getpidofnode(nodeid))
      Process.exit(getpidofnode(nodeid), :kill)
      # IO.puts "node killed #{nodeid}"
      Task.shutdown(nodeprocesspid, :brutal_kill)







    end
  end
end

