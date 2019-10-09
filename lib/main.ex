defmodule Parsearg do

  def main(args) do
    args |> parse_args |> callfunctions
  end
  defp parse_args(args) do
    {_,parameters,_} = OptionParser.parse(args, switches: [help: :boolean])
    parameters
  end

  def callfunctions(parameters) do
    # IO.puts numnodes
    # global key-value registry to store node pids
    numnodes = String.to_integer(Enum.at(parameters,0))
    topology = Enum.at(parameters,1)
    algorithm = Enum.at(parameters,2)
    numnodestofail = Enum.at(parameters, 3)
    Registry.start_link(keys: :unique, name: :storenodepids)
    IO.puts "nodes about to fail are, #{numnodestofail}"
    failnodes = []
    # for i <- 1..noofnodestofail do
    #   IO.puts "rand, #{failnodes}"
    #   failnodes = failnodes ++ Enum.random(1..numnodes)
    # end
    failnodes = Enum.reduce(1..noofnodestofail, [], fn(a,acc)-> acc++[Enum.random(1..numnodes)] end)
    IO.puts "random numbers are , #{failnodes}"
    cond do
      topology == "full" -> GossipTopologies.full(numnodes,failnodes,algorithm)
      topology == "line" -> GossipTopologies.line(numnodes,failnodes,algorithm)
      topology == "rand2D" -> GossipTopologies.random2DGrid(numnodes,failnodes,algorithm)
      topology == "3Dtorus" -> GossipTopologies.torus3D(numnodes,failnodes,algorithm)
      topology == "honeycomb" -> GossipTopologies.honeyComb(numnodes,failnodes,algorithm)
      topology == "randhoneycomb" -> GossipTopologies.honeyCombRandom(numnodes,failnodes,algorithm)
    end
    cond do
      algorithm == "gossip" ->  GossipCounter.startspreadinggossip(numnodes,topology,algorithm)
      algorithm == "push-sum" ->  GossipCounter.startspreadingpushsum(numnodes,topology,algorithm)
    end



    # GossipTopologies.full(numnodes,failnodes)
    # GossipCounter.startspreadinggossip(numnodes,topology,algorithm)
    #foo()
    #GossipCounter.startspreadingpushsum(numnodes,topology,algorithm)
  end
end
