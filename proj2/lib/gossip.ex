defmodule GossipServer do
  use GenServer

  # def start_link([counter,list,s,w]) do
  #   GenServer.start_link(__MODULE__,[counter,list,s,w]) #counter,list,s,w
  # end

  def start_link(msg,node) do
    {:ok,pid}=GenServer.start_link(__MODULE__,[0,[],msg,node]) #counter,list,s,w
    :ets.insert(:processTable, {node,pid})
  end

  def init(values) do
    #IO.inspect(values)
    {:ok,values}
  end

  def insertNeighbour(neigh_list,to) do
    GenServer.cast(to, {:putNeighbour,neigh_list})
  end


  def handle_cast({:updateCounter,new_count},state) do
    [_counter,curr_list,s,w] = state
    {:noreply,[new_count,curr_list,s,w]}
  end

  def setCounter(pid,counter) do
    GenServer.cast(pid,{:updateCounter,counter})
  end

  def updateNeighbour(to,element) do
    GenServer.cast(to,{:updateList,element})
  end

  def handle_cast({:updateList,elementToBeRemoved},state) do
    [counter,curr_list,s,w] = state
    {:noreply,[counter,curr_list--[elementToBeRemoved],s,w]}
  end



  def getvalues(processID) do
    state=GenServer.call(processID,{:getstate})
    state
  end

  def handle_call({:getstate},_from,state) do
    {:reply,state,state}
  end

  def handle_call({:getCounter},_from,state) do
    [counter,_curr_list,_s,_w] = state
    {:reply,counter,state}
  end



  def getRandomNeighbour(curr_list,threshold) do
    if curr_list == [] do
      []
    else
      rand_neigh = Enum.random(curr_list)
      [{_,rand_pid}] = :ets.lookup(:processTable, rand_neigh)
      counter = GenServer.call(rand_pid,{:getCounter})

      if(counter==threshold) do
        updated_list = curr_list -- [rand_neigh]
        updateNeighbour(rand_pid,rand_neigh)
        getRandomNeighbour(updated_list,threshold)
      else
        rand_neigh
      end
    end
  end


  def handle_cast({:putNeighbour,neighbour},state) do
    [counter,curr_list,s,w] = state
    {:noreply,[counter,curr_list++neighbour,s,w]}
  end

  def handle_cast({:saveMessage,new_msg},state) do
    [count,curr_list,msg,w] = state
    {:noreply,[count,curr_list,new_msg,w]}
  end

  def sendGossip(new_msg,processID,stime) do
    [count,curr_list,msg,w] = GenServer.call(processID,{:getstate})
    GenServer.cast(processID,{:saveMessage,new_msg})
    if count < 10 do
      count = count + 1
      if count == 10 do
        #IO.puts(count)
        converge(stime)
      end
      setCounter(processID,count)
      rand_neigh = getRandomNeighbour(curr_list,10)
      if rand_neigh != [] do
        [{_,rand_pid}] = :ets.lookup(:processTable, rand_neigh)
        sendGossip(new_msg, rand_pid,stime)
        sendGossip(new_msg,processID,stime)
      else
        converge(stime)
      end
    end
  end



#---------------------------Converge----------------------
  def converge(startTime) do
    [{_,currentCount}]=:ets.lookup(:counterTable,"counter")
    c = currentCount + 1
    :ets.insert(:counterTable,{"counter",c})
    IO.puts(c)
    if(c>=trunc(100*0.7)) do

      endTime = System.monotonic_time(:millisecond)
      conTime = endTime - startTime
      IO.puts(conTime)
      #IO.puts("Convergence reached")
      #Process.sleep(100)
      System.halt(1)
      #GenServer.call(self(),{:converge})
    end
  end

  # def handle_call({:converge},_from,_) do
  #   IO.puts("Convergence reached")
  #   System.halt(1)
  # end
end
