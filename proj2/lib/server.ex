defmodule Server do
  use GenServer

  # def start_link([counter,list,s,w]) do
  #   GenServer.start_link(__MODULE__,[counter,list,s,w]) #counter,list,s,w
  # end

  def start_link(node) do
    {:ok,pid}=GenServer.start_link(__MODULE__,[0,[],node,1]) #counter,list,s,w
    :ets.insert(:processTable, {node,pid})
  end

  def init(values) do
    #IO.inspect(values)
    {:ok,values}
  end

  def insertNeighbour(neigh_list,to) do
    GenServer.cast(to, {:putNeighbour,neigh_list})
  end


  #-----------------PushSum----------------------

  def startPushSum(to) do
    GenServer.cast(to,:executePushSum)
  end

  def handle_cast({:updateCounter,new_count},state) do
    [_counter,curr_list,s,w] = state
    {:noreply,[new_count,curr_list,s,w]}
  end

  def setCounter(pid,counter) do
    GenServer.cast(pid,{:updateCounter,counter})
  end


  def calculateCount(diff,count) do
    if(diff < :math.pow(10,-10) && (count==2)) do
      converge()
      -1
    else
      if(diff >= :math.pow(10,-10)) do 0 else count+1 end
    end
  end

  @spec updateNeighbour(atom | pid | {atom, any} | {:via, atom, any}, any) :: :ok
  def updateNeighbour(to,element) do
    GenServer.cast(to,{:updateList,element})
  end

  def handle_cast({:updateList,elementToBeRemoved},state) do
    [counter,curr_list,s,w] = state
    {:noreply,[counter,curr_list--[elementToBeRemoved],s,w]}
  end
  def updateState(pid,sn,wn,c) do
    GenServer.cast(pid,{:updateSW,sn,wn,c})
  end

  #def sendToRandom(to,s,w) do
    #GenServer.cast(to,{:sendPushSum,s,w})
   # 0
  #end

  def getvalues(processID) do
    state=GenServer.call(processID,{:getstate})
    state
  end

  def handle_cast({:updateSW,sn,wn,c},state) do
    [counter,curr_list,_s,_w] = state
    {:noreply,[c,curr_list,sn,wn]}
  end

  def handle_call({:getstate},_from,state) do
    {:reply,state,state}
  end

  def handle_call({:getCounter},_from,state) do
    [counter,_curr_list,_s,_w] = state
    {:reply,counter,state}
  end

  def sendPushSum(sn,wn,processID) do
    [count,curr_list,s,w] = GenServer.call(processID,{:getstate})
    #IO.puts(counter)
      old_avg = s/w
      new_avg = (s+sn)/(w+wn)
      diff = abs(old_avg-new_avg)
      rand_neigh = getRandomNeighbour(curr_list)
      [{_,rand_pid}] = :ets.lookup(:processTable, rand_neigh)
      if count != -1 do
        ncount = calculateCount(diff,count)
        updateState(processID,(s+sn)/2,(w+wn)/2,ncount)
      end
        if rand_neigh != [] do
          val1 = if(count != -1) do (s+sn)/2 else s/2 end
          val2 = if(count != -1) do (w+wn)/2 else w/2 end
          #IO.puts("From #{inspect pname} to #{inspect neighNode}")
          spawn fn -> sendPushSum(val1,val2,rand_pid) end
          Process.sleep(100)
        else
          converge()
        end
  end


  #-------------------Gossip-----------------------
  def pushMessage(to, message) do
    GenServer.cast(to, {:sendMessage,message})
  end

  def handle_cast({:putNeighbour,neighbour},state) do
    [counter,curr_list,s,w] = state
    {:noreply,[counter,curr_list++neighbour,s,w]}
  end

  def handle_cast({:sendMessage,message},state) do
    [counter,curr_list,s,w] = state
    counter = counter+1
    [{_,count}]=:ets.lookup(:counterTable, "counter")
    [{_,status}] = :ets.lookup(:trackTable, "check")
    if count >=4  and status == 0 do
      :ets.insert(:trackTable, {"check",1})
      converge()
    end
    if counter==10 and count<4 do
      [{_,count}]=:ets.lookup(:counterTable, "counter")
      :ets.insert(:counterTable, {"counter",count+1})
    end
    [{_,count}]=:ets.lookup(:counterTable, "counter")
    if counter <10 and count <4 do
      rand_neigh = getRandomNeighbour(curr_list)
      [{_,pid}] = :ets.lookup(:processTable, rand_neigh)
      GenServer.cast(pid, {:sendMessage,message})
      GenServer.cast(self(),{:sendMessage,message})
    end
    {:noreply,[counter,curr_list,s,w]}
  end


#---------------------------Converge----------------------
  def converge() do
    [{_,currentCount}]=:ets.lookup(:counterTable,"counter")
    c = currentCount + 1
    :ets.insert(:counterTable,{"counter",c})

    if(c>=trunc(4*0.9)) do
      IO.puts("Convergence reached")
      System.halt(1)
      #GenServer.call(self(),{:converge})
    end
  end

  def handle_call({:converge},_from,_) do
    IO.puts("Convergence reached")
    System.halt(1)
  end

  def getRandomNeighbour(curr_list) do
    if curr_list == [] do
      []
    else
      rand_neigh = Enum.random(curr_list)
      [{_,rand_pid}] = :ets.lookup(:processTable, rand_neigh)
      counter = GenServer.call(rand_pid,{:getCounter})

      if(counter>=3) do
        updated_list = curr_list -- rand_neigh
        updateNeighbour(rand_pid,rand_neigh)
        getRandomNeighbour(updated_list)
      else
        rand_neigh
      end
    end

  end


end
