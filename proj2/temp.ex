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

  def rand2D(numNodes) do
    x=Enum.reduce(1..numNodes, [], fn(x,list) -> list ++ [:rand.uniform] end)
    y=Enum.reduce(1..numNodes, [], fn(y,list) -> list ++ [:rand.uniform] end)
    Enum.each(1..numNodes, fn(i) ->
        list = Enum.filter(1..numNodes, fn(j) -> j == distance(i,j,x,y) end)
    end)
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

  def hexagon(num_Nodes) do
    numNodes = round(:math.pow(round(:math.sqrt(num_Nodes)),2))
    rowcnt = round(:math.sqrt(numNodes))
    for i <- 1..numNodes do
      list = cond do
        rem(rowcnt,2) == 0 -> even_hex(i,numNodes,rowcnt)
        rem(rowcnt,2) != 0 -> odd_hex(i,numNodes,rowcnt)
      end
      IO.puts i
      IO.inspect list
    end
  end


  def hexagon_rand(num_Nodes) do
    numNodes = round(:math.pow(round(:math.sqrt(num_Nodes)),2))
    rowcnt = round(:math.sqrt(numNodes))
    for i <- 1..numNodes do
      list = cond do
        rem(rowcnt,2) == 0 -> even_hex(i,numNodes,rowcnt) ++ [:rand.uniform(numNodes)]
        rem(rowcnt,2) != 0 -> odd_hex(i,numNodes,rowcnt) ++ [:rand.uniform(numNodes)]
      end
      IO.puts i
      IO.inspect list
    end
  end
