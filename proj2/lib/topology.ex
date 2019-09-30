defmodule Topology do
  def main(_args) do
    numNodes = 4
    topology = "line"
    algorithm = "push-sum"
    :ets.new(:processTable, [:set, :public, :named_table])
    :ets.new(:counterTable, [:set, :public, :named_table])
    :ets.new(:trackTable,[:set, :public, :named_table])
    Enum.each(1..numNodes, fn(x)->
      Server.start_link(x)

      :ets.insert(:trackTable, {"check",0})
      :ets.insert(:counterTable,{"counter",0})
    end)
    case algorithm do
       "gossip"-> IO.puts("Gossip")
       "push-sum"->IO.puts("Push Sum")

        _->IO.puts("Invalid Input")
    end

    _list=case topology do
       "full"->full(numNodes)
       "line"->line(numNodes)
       "rand2D"->rand_2d(numNodes)
       "3Dtorus"->torus_3d(numNodes)
       "honeycomb"->honeycomb(numNodes)
       "randhoneycomb"->rand_honeycomb(numNodes)
    end
  end

  def execute(numNodes) do
    rand_node = Enum.random(1..numNodes)
    [{_,pid}] = :ets.lookup(:processTable, rand_node)
    message = "gossip"
    Server.pushMessage(pid,message)
  end

  def pushSum(numNodes) do
    IO.puts("Calling ps")
    Enum.each(1..numNodes, fn(x)->
      [{_,pid}] = :ets.lookup(:processTable, x)
      #Server.startPushSum(pid)
      #state=Server.getvalues(pid)
      #[counter,curr_list,s,w] = state
      [_counter,_curr_list,s,w] = GenServer.call(pid,{:getstate})
      Server.sendPushSum(0,0,pid)
    end)

    # rand_node = Enum.random(1..numNodes)
    # [{_,pid}] = :ets.lookup(:processTable, rand_node)
    # Server.startPushSum(pid)
  end

  def full(_numNodes) do

  end

  def line(numNodes) do
    Enum.each(1..numNodes, fn(x)->
      list = cond do
        x==1->[x+1]
        x==numNodes->[x-1]
        true->[x-1,x+1]
     end
      [{_,pid}] = :ets.lookup(:processTable, x)
      Server.insertNeighbour(list,pid)
    end)
    #execute(numNodes)
    pushSum(numNodes)

  end

  def rand_2d(_numNodes) do

  end

  def torus_3d(_numNodes) do

  end

  def honeycomb(_numNodes) do

  end

  def rand_honeycomb(_numNodes) do

  end

end
Topology.main([])
