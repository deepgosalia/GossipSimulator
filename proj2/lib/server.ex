defmodule Server do
  use GenServer

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

  def updateNeighbour(to,element) do
    GenServer.cast(to,{:updateList,element})
  end

  def handle_cast({:updateList,elementToBeRemoved},state) do
    [counter,curr_list,s,w] = state
    {:noreply,[counter,curr_list--[elementToBeRemoved],s,w]}
  end

  def updateState(pid,sn,wn) do
    GenServer.cast(pid,{:updateSW,sn,wn})
  end
  def handle_cast({:updateSW,sn,wn},state) do
    [counter,curr_list,_s,_w] = state
    {:noreply,[counter,curr_list,sn,wn]}
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

  def sendPushSum(sn,wn,processID,stime) do
    [count,curr_list,s,w] = GenServer.call(processID,{:getstate})
      old_avg = s/w
      new_avg = (s+sn)/(w+wn)
      rand_neigh = getRandomNeighbour(curr_list,3)
      if count !=3 do
        diffAvg = abs(old_avg-new_avg)
        threshold = :math.pow(10,-10)
        #IO.puts(new_avg)
        if (diffAvg < threshold) do
          count = count + 1
          if count == 3 do
            IO.puts(new_avg)
            converge(stime)
          end
          setCounter(processID,count)
        else
          #since we are looking at the consecutive round so we again set counter to 0
          count = 0
          setCounter(processID,count)
        end
        updateState(processID,(s+sn)/2,(w+wn)/2)
      end
      if rand_neigh != [] do
        [{_,rand_pid}] = :ets.lookup(:processTable, rand_neigh)
        sendToNeighbour(sn,wn,s,w,rand_pid,count,stime)
      else
        converge(stime)
      end
  end

  def sendToNeighbour(sn,wn,s,w,pid,countStatus,stime) do
    # if count == 3 send old value..means it is already terminated but can send if it has neighbour
    if countStatus == 3 do
     sendPushSum(s/2,w/2,pid,stime)
     #Process.sleep(100)
    else
      sendPushSum((s+sn)/2,(w+wn)/2,pid,stime)
    end
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

  #-------------------Gossip-----------------------
  def pushMessage(to, message) do
    GenServer.cast(to, {:sendMessage,message})
  end

  def handle_cast({:putNeighbour,neighbour},state) do
    [counter,curr_list,s,w] = state
    {:noreply,[counter,curr_list++neighbour,s,w]}
  end

  def handle_cast({:saveMessage,new_msg},state) do
    [count,curr_list,msg,w] = state
    {:noreply,[count,curr_list,new_msg,w]}
  end

  # def sendGossip(new_msg,processID,stime) do
  #   [count,curr_list,msg,w] = GenServer.call(processID,{:getstate})
  #   GenServer.cast(processID,{:saveMessage,new_msg})
  #   if count != 10 do
  #     count = count + 1
  #     if count == 10 do
  #       converge(stime)
  #     end
  #     setCounter(processID,count)
  #     rand_neigh = getRandomNeighbour(curr_list,10)
  #     if rand_neigh != [] do
  #       [{_,rand_pid}] = :ets.lookup(:processTable, rand_neigh)
  #       sendGossip(new_msg, rand_pid,stime)
  #     else
  #       converge(stime)
  #     end
  #   end
  # end






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

  def handle_call({:converge},_from,_) do
    IO.puts("Convergence reached")
    System.halt(1)
  end
end
