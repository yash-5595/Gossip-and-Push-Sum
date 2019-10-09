defmodule GossipTopologies do
  def line(numnodes, failnodes,algorithm) do
    for i <- 1..numnodes do
      neighboursList =
        cond do
          i == 1 -> [i + 1]
          i == numnodes -> [i - 1]
          true -> [i - 1, i + 1]
        end
        IO.puts i
        IO.puts neighboursList
        cond do
          algorithm == "gossip" ->  spawn(fn -> GossipGenserver.start(i, neighboursList, failnodes) end)
          algorithm == "push-sum" ->  spawn(fn -> PushSum.start(i, neighboursList, failnodes) end)

        end
      end
  end


  def full(numnodes, failnodes,algorithm) do
    for i <- 1..numnodes do
      neighboursList = Enum.to_list(1..numnodes)
      neighboursList = List.delete(neighboursList, i)
        IO.puts i
        IO.puts neighboursList
        cond do
          algorithm == "gossip" ->  spawn(fn -> GossipGenserver.start(i, neighboursList, failnodes) end)
          algorithm == "push-sum" ->  spawn(fn -> PushSum.start(i, neighboursList, failnodes) end)

        end
    #do some shit here also please
    end
  end

  def nth_root(n, x, precision \\ 1.0e-5) do
    f = fn(prev) -> ((n - 1) * prev + x / :math.pow(prev, (n-1))) / n end
    fixed_point(f, x, precision, f.(x))
  end

  defp fixed_point(_, guess, tolerance, next) when abs(guess - next) < tolerance, do: next
  defp fixed_point(f, _, tolerance, next), do: fixed_point(f, next, tolerance, f.(next))



  def getNeighbour2D(a,k,x,y,coordinates) do
    p = cond do
       k == a -> []
       dist = :math.sqrt(:math.pow(x-Enum.at(Map.get(coordinates,k), 0),2)+:math.pow(y-Enum.at(Map.get(coordinates,k), 1),2)) <=0.1 ->
            [k]
         true ->
           []
         end
        p
  end


  def random2DGrid(numnodes, failnodes,algorithm) do
    coords = %{}
      coords = Enum.reduce(1..numnodes,%{},fn (k,acc) ->
        x = Enum.random(1..numnodes)/numnodes
        y = Enum.random(1..numnodes)/numnodes
        Map.merge(Map.put(coords,k,[x,y]),acc)
      end)
    for a <- 1..numnodes do
      cords = Map.get(coords,a)
      x = Enum.at(cords, 0)
      y = Enum.at(cords, 1)
      neighboursList = Enum.reduce(1..numnodes,[],fn(k,acc)-> acc ++ getNeighbour2D(a,k,x,y,coords)
      end)
      IO.puts a
      IO.puts neighboursList
      #do shit with neighbours here
      cond do
        algorithm == "gossip" ->  spawn(fn -> GossipGenserver.start(a, neighboursList, failnodes) end)
        algorithm == "push-sum" ->  spawn(fn -> PushSum.start(a, neighboursList, failnodes) end)

      end

    end
  end


  def torus3D(numnodes, failnodes,algorithm) do
    side = Kernel.trunc(round(nth_root(3, numnodes)))
    n =  Kernel.trunc(:math.pow(side,3))
    coords = %{}
      coords = Enum.reduce(1..n,%{},fn (k,acc) ->
        layer = Kernel.trunc((k-1)/Kernel.trunc(:math.pow(side,2)))
        new = rem((k-1),Kernel.trunc(:math.pow(side,2)))
        row = Kernel.trunc((new)/side)
        column = rem((new),side)
        Map.merge(Map.put(coords,k,[layer,row,column]),acc)
      end)
      for a <- 1..n do
        cords = Map.get(coords,a)
        layer = Enum.at(cords, 0)
        row = Enum.at(cords, 1)
        column = Enum.at(cords, 2)
        up = cond do
          layer == 0 -> [side-1,row,column]
          true -> [layer-1,row,column]
        end
        down = cond do
          layer == (side-1) -> [0,row,column]
          true -> [layer+1,row,column]
        end
        left = cond do
          column == 0 -> [layer,row,side-1]
          true -> [layer,row,column-1]
        end
        right = cond do
          column == (side-1) -> [layer,row,0]
          true -> [layer,row,column+1]
        end
        front = cond do
          row == 0 -> [layer,side-1,column]
          true -> [layer,row-1,column]
        end
        back = cond do
          row == (side-1) -> [layer,0,column]
          true -> [layer,row+1,column]
        end
        nbr_cords = Tuple.to_list({up,down,left,right,front,back})
        neighboursList = Enum.reduce(1..n,[],fn(k,acc) ->
          coordinates = Map.get(coords,k)
          if Enum.member?(nbr_cords, coordinates) do
            acc = acc ++ [k]
            acc
        else
          acc = acc ++ []
            acc
        end

    end)
  # each a here has neighbours in neighbors do the shit
    cond do
      algorithm == "gossip" ->  spawn(fn -> GossipGenserver.start(a, neighboursList, failnodes) end)
      algorithm == "push-sum" ->  spawn(fn -> PushSum.start(a, neighboursList, failnodes) end)

    end
      IO.puts a
      IO.puts neighboursList
  end
  end

  def honeyComb(numNodes, failnodes,algorithm) do
    rem = rem(numNodes,6)
    n = cond do
      rem == 0 -> numNodes
      true -> numNodes + 6 - rem
    end
    coords = %{}
      coords = Enum.reduce(1..n,%{},fn (k,acc) ->
        row = Kernel.trunc((k-1)/6)
        column = rem((k-1),6)
        Map.merge(Map.put(coords,k,[row,column]),acc)
      end)
      for a <- 1..n do
        neighbours = []
        cords = Map.get(coords,a)
        row = Enum.at(cords, 0)
        column = Enum.at(cords, 1)
        up = cond do
          row == 0 -> []
          true -> [row-1,column]
        end
        down = cond do
          row == Kernel.trunc((n-1)/6) -> []
          true -> [row+1,column]
        end
        left = cond do
          column == 0 -> []
          true -> [row,column-1]
        end
        right = cond do
          column == 5 -> []
          true -> [row,column+1]
      end
      neighbours = cond do
        rem(row,2) == 0 ->
          cond do
            rem(column,2) == 0 -> [up,down,left]
            rem(column,2) == 1 -> [up,down,right]
          end
          rem(row,2) == 1 ->
            cond do
              rem(column,2) == 0 -> [up,down,right]
              rem(column,2) == 1 -> [up,down,left]
            end
      end
      neighboursList = Enum.reduce(1..n,[],fn(k,acc) ->
        coordinates = Map.get(coords,k)
        if Enum.member?(neighbours, coordinates) do
          acc = acc ++ [k]
          acc
      else
        acc = acc ++ []
          acc
      end

  end)
  #here for each a, neighboursList is its neighbours..do shit here
  cond do
    algorithm == "gossip" ->  spawn(fn -> GossipGenserver.start(a, neighboursList, failnodes) end)
    algorithm == "push-sum" ->  spawn(fn -> PushSum.start(a, neighboursList, failnodes) end)

  end
  IO.puts a
  IO.puts neighboursList
    end
  end


  def honeyCombRandom(numNodes, failnodes,algorithm) do
    rem = rem(numNodes,6)
    n = cond do
      rem == 0 -> numNodes
      true -> numNodes + 6 - rem
    end
    coords = %{}
      coords = Enum.reduce(1..n,%{},fn (k,acc) ->
        row = Kernel.trunc((k-1)/6)
        column = rem((k-1),6)
        Map.merge(Map.put(coords,k,[row,column]),acc)
      end)
      for a <- 1..n do
        neighbours = []
        cords = Map.get(coords,a)
        row = Enum.at(cords, 0)
        column = Enum.at(cords, 1)
        up = cond do
          row == 0 -> []
          true -> [row-1,column]
        end
        down = cond do
          row == Kernel.trunc((n-1)/6) -> []
          true -> [row+1,column]
        end
        left = cond do
          column == 0 -> []
          true -> [row,column-1]
        end
        right = cond do
          column == 5 -> []
          true -> [row,column+1]
      end
      neighbours = cond do
        rem(row,2) == 0 ->
          cond do
            rem(column,2) == 0 -> [up,down,left]
            rem(column,2) == 1 -> [up,down,right]
          end
          rem(row,2) == 1 ->
            cond do
              rem(column,2) == 0 -> [up,down,right]
              rem(column,2) == 1 -> [up,down,left]
            end
      end
      nbrs = Enum.reduce(1..n,[],fn(k,acc) ->
        coordinates = Map.get(coords,k)
        if Enum.member?(neighbours, coordinates) do
          acc = acc ++ [k]
          acc
      else
        acc = acc ++ []
          acc
      end

  end)
  others = Enum.to_list(1..n) -- nbrs
  neighboursList = nbrs ++ [Enum.random(others)]

  #here for each a neighboursList is list of neighbours, do shit here
  cond do
    algorithm == "gossip" ->  spawn(fn -> GossipGenserver.start(a, neighboursList, failnodes) end)
    algorithm == "push-sum" ->  spawn(fn -> PushSum.start(a, neighboursList, failnodes) end)

  end
  IO.puts a
  IO.puts neighboursList
    end
  end










end
