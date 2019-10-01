defmodule Topology do
  def start() do
    #[temp,topology,algorithm] = System.argv()
    #numNodes = String.to_integer(temp)
    #numNodes = Enum.at(args,0)
    #IO.puts(numNodes)
    numNodes = 100
    topology = "randhoneycomb"
    algorithm = "push-sum"
    :ets.new(:processTable, [:set, :public, :named_table])
    :ets.new(:counterTable, [:set, :public, :named_table])
    :ets.new(:trackTable,[:set, :public, :named_table])
    Enum.each(1..numNodes, fn(x)->
      if algorithm == "push-sum" do
        Server.start_link(x)
      else
        GossipServer.start_link("",x)
      end
      :ets.insert(:trackTable, {"check",0})
      :ets.insert(:counterTable,{"counter",0})
    end)

    _list=case topology do
      "full"->full(numNodes,algorithm)
      "line"->line(numNodes,algorithm)
      "rand2D"->rand_2d(numNodes,algorithm)
      "3Dtorus"->torus_3d(numNodes)
      "honeycomb"->honeycomb(numNodes,algorithm)
      "randhoneycomb"->rand_honeycomb(numNodes,algorithm)
   end

    case algorithm do
       "gossip"-> execute(numNodes)
       "push-sum"->pushSum(numNodes)
        _->IO.puts("Invalid Input")
    end
  end

  def execute(numNodes) do
    rand_node = Enum.random(1..numNodes)
    [{_,pid}] = :ets.lookup(:processTable, rand_node)
    message = "gossip"
    stime = System.monotonic_time(:millisecond)
    GossipServer.sendGossip(message,pid,stime)
  end

  def pushSum(numNodes) do
    Enum.each(1..numNodes, fn(x)->
      [{_,pid}] = :ets.lookup(:processTable, x)
      stime = System.monotonic_time(:millisecond)
      Server.sendPushSum(0,0,pid,stime)
    end)
  end

  def full(numNodes,algorithm) do
    Enum.each(1..numNodes, fn(x)->
      list= Enum.filter(1..numNodes, fn(i) -> i !=x end)
      [{_,pid}] = :ets.lookup(:processTable, x)
      if algorithm == "push-sum" do
        Server.insertNeighbour(list,pid)
      else
        GossipServer.insertNeighbour(list,pid)
      end
    end)
  end

  def line(numNodes,algorithm) do
    Enum.each(1..numNodes, fn(x)->
      list = cond do
        x==1->[x+1]
        x==numNodes->[x-1]
        true->[x-1,x+1]
     end
      [{_,pid}] = :ets.lookup(:processTable, x)
      if algorithm == "push-sum" do
        Server.insertNeighbour(list,pid)
      else
        GossipServer.insertNeighbour(list,pid)
      end

    end)
    #execute(numNodes)
    #pushSum(numNodes)

  end

  def rand_2d(numNodes,algorithm) do
    x=Enum.reduce(1..numNodes, [], fn(x,list) -> list ++ [:rand.uniform] end)
    y=Enum.reduce(1..numNodes, [], fn(y,list) -> list ++ [:rand.uniform] end)
    Enum.each(1..numNodes, fn(i) ->
        list = Enum.filter(1..numNodes, fn(j) -> j == distance(i,j,x,y) end)
        [{_,pid}] = :ets.lookup(:processTable, i)
        if algorithm == "push-sum" do
          Server.insertNeighbour(list,pid)
        else
          GossipServer.insertNeighbour(list,pid)
      end

      end)
  end

  def torus_3d(_numNodes) do

  end

  def honeycomb(num_Nodes,algorithm) do
    numNodes = round(:math.pow(round(:math.sqrt(num_Nodes)),2))
    rowcnt = round(:math.sqrt(numNodes))
    for i <- 1..numNodes do
      list = cond do
        rem(rowcnt,2) == 0 -> even_hex(i,numNodes,rowcnt)
        rem(rowcnt,2) != 0 -> odd_hex(i,numNodes,rowcnt)
      end
      [{_,pid}] = :ets.lookup(:processTable, i)
      if algorithm == "push-sum" do
        Server.insertNeighbour(list,pid)
      else
        GossipServer.insertNeighbour(list,pid)
      end
    end
  end





  def rand_honeycomb(num_Nodes,algorithm) do
    numNodes = round(:math.pow(round(:math.sqrt(num_Nodes)),2))
    rowcnt = round(:math.sqrt(numNodes))
    for i <- 1..numNodes do
      list = cond do
        rem(rowcnt,2) == 0 -> even_hex(i,numNodes,rowcnt) ++ [:rand.uniform(numNodes)]
        rem(rowcnt,2) != 0 -> odd_hex(i,numNodes,rowcnt) ++ [:rand.uniform(numNodes)]
      end
      [{_,pid}] = :ets.lookup(:processTable, i)
      if algorithm == "push-sum" do
        Server.insertNeighbour(list,pid)
      else
        GossipServer.insertNeighbour(list,pid)
      end
    end
  end

  def odd_hex(i,numNodes,rowcnt) do
    list =  cond do
      i == 1 -> [i+1,i+rowcnt]
      i == rowcnt -> [i-1,i+rowcnt]
      i == numNodes - rowcnt + 1 -> [i+1,i-rowcnt]
      i == numNodes -> [i-rowcnt]
      i < rowcnt and rem(i,2) == 0 -> [i-1,i+rowcnt]     #1st row odd
      i < rowcnt and rem(i,2) != 0 -> [i+1,i+rowcnt]     #1st row odd
      i > numNodes - rowcnt + 1 and rem(rowcnt,2) != 0 and rem(i,2) == 0 -> [i-1,i-rowcnt]  #last row odd
      i > numNodes - rowcnt + 1 and rem(rowcnt,2) != 0 and rem(i,2) != 0 -> [i+1,i-rowcnt]  #last row odd
      rem(i-1,rowcnt) == 0 and rem(i,2) == 0 -> [i-rowcnt,i+rowcnt]             #1st col odd
      rem(i-1,rowcnt) == 0 and rem(i,2) != 0 -> [i+1,i-rowcnt,i+rowcnt]         #1st col odd
      rem(i,rowcnt) == 0 and rem(i,2) == 0 -> [i-1,i-rowcnt,i+rowcnt]           #last col odd
      rem(i,rowcnt) == 0 and rem(i,2) != 0 -> [i-rowcnt,i+rowcnt]               #last col odd
      rem(rowcnt,2) != 0 and rem(i,2) == 0 -> [i-1,i+rowcnt,i-rowcnt]           #odd
      rem(rowcnt,2) != 0 and rem(i,2) != 0 -> [i+1,i+rowcnt,i-rowcnt]           #odd
    end
  end

def even_hex(i,numNodes,rowcnt) do
  j = div(i,rowcnt)
  list =  cond do
    i == 1 -> [i+1,i+rowcnt]
    i == rowcnt -> [i-1,i+rowcnt]
    i == numNodes - rowcnt + 1 -> [i-rowcnt]
    i == numNodes -> [i-rowcnt]
    i < rowcnt and rem(i,2) == 0 -> [i-1,i+rowcnt]     #1st row
    i < rowcnt and rem(i,2) != 0 -> [i+1,i+rowcnt]     #1st row
    i > numNodes - rowcnt + 1 and rem(i,2) == 0 -> [i+1,i-rowcnt]            #last row
    i > numNodes - rowcnt + 1 and rem(i,2) == 1 -> [i-1,i-rowcnt]            #last row
    rem(i-1,rowcnt) == 0 and rem(div(i-1,rowcnt),2) == 1 -> [i-rowcnt,i+rowcnt]             #1st col
    rem(i-1,rowcnt) == 0 and rem(div(i-1,rowcnt),2) == 0 -> [i+1,i-rowcnt,i+rowcnt]         #1st col
    rem(i,rowcnt) == 0 and rem(div(i,rowcnt),2) == 1  -> [i-1,i-rowcnt,i+rowcnt]           #last col odd
    rem(i,rowcnt) == 0 and rem(div(i,rowcnt),2) == 0  -> [i-rowcnt,i+rowcnt]               #last col odd
    rem(i-(i-(rowcnt * j)),rowcnt) == 0 and rem(i,2) == 0-> [i-1,i-rowcnt,i+rowcnt]        # if last row has a even multiple
    rem(i-(i-(rowcnt * j)),rowcnt) == 0 and rem(i,2) == 1-> [i+1,i-rowcnt,i+rowcnt]
    rem(i-(i-(rowcnt * j)),rowcnt) == 1 and rem(i,2) == 0-> [i+1,i-rowcnt,i+rowcnt]        #if last row has odd
    rem(i-(i-(rowcnt * j)),rowcnt) == 1 and rem(i,2) == 1-> [i-1,i-rowcnt,i+rowcnt]
  end
end
  def distance(i,j,x,y) do
    if i != j do
      x1=Enum.at(x,i-1)
      y1=Enum.at(y,i-1)
      x2=Enum.at(x,j-1)
      y2=Enum.at(y,j-1)
      d = :math.sqrt(((x2 - x1) * (x2 - x1)) + ((y2 - y1) * (y2 - y1)))
      if d < 0.1 do
          j
      end
  end
  end
end
Topology.start()
