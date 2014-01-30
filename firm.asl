!start.
	
+!start <-
	.my_name(Me);
	!boundRandom(9,N);
	+neededWorkers(N);
	.broadcast(tell, introduction(Me)).

+!boundRandom(BOUND, RES) <-
	.random(T);
	RES = math.round(BOUND * T +1).

+demandOver <-
	.findall([W, Worker], demand(Worker,W), NewDemandsList);
	.abolish(demand(_,_));
	+demands(NewDemandsList);
	.findall(Employed, accept(Employed, W), OldEmployedList);
	.abolish(accept(_,_));
	!updateWages(NewDemandsList, OldEmployedList, []).
	
+!updateWages(New, Old, Res) <-
	.length(New, NewLength);
	NewLength = NewLength;
	if (NewLength > 0) {
		.nth(0, New, NewDemand);
		.delete(0, New, TailNew);
		.nth(1, NewDemand, NewDemandName);
		if (.member(NewDemandName, Old)) {
			.concat([NewDemand], Res, NewRes);
			!updateWages(TailNew, Old, NewRes);
		} else {
			!updateWages(TailNew, Old, Res);
		}
	}
	else {
		.sort(Res, SortedRes);
		!chooseWorkers(SortedRes);
	}
	.

+!chooseWorkers(OldEmployedDemandsList) : neededWorkers(Nwork) & demands(DemandsList) <-
	-demands(DemandsList);
	.difference(DemandsList, OldEmployedDemandsList, NewEmployedDemandsList);
	.sort(NewEmployedDemandsList, SortedNEDL);
	.concat(OldEmployedDemandsList, SortedNEDL, Demands);
	//.print("La lista dei vecchi è ", OldEmployedDemandsList);
	//.print("La lista corretta è ", Demands);
	.length(Demands, Length);
	//perché???
	Length = Length;
	for( .range(I, 0, Nwork - 1) ) {
		if( Length > I) {
			.nth(I, Demands, Employee);
			!employ(Employee);
		}
		else {
		}
	}
	sentAllJobOffer;
	.

+!employ(E) <-
	.nth(1, E, Worker);
	.my_name(Me);
	.send(Worker, tell, jobOffer(Me)).

+jobMarketClosed : neededWorkers(N) <- 
	.findall(E, accept(E, W), L);
	.length(L, Employed);
	endCycle(N-Employed).

