// Agent firm in project SimpleEconomy.mas2j

/* Initial beliefs and rules */

/* Initial goals */

!start.

/* Plans */
	
+!start <-
	.my_name(Me);
	!boundRandom(9,N);
	+neededWorkers(N);
	.broadcast(tell, introduction(Me)).

+!boundRandom(BOUND, RES) <-
	.random(T);
	RES = math.round(BOUND * T +1).

+demandOver <-
	!chooseWorkers.

+!chooseWorkers : neededWorkers(Nwork) <-
	.findall([W, Worker], demand(Worker,W), L);
	.abolish(demand(_,_));
	.findall([W, Employed], accept(Employed, W), Old);
	.abolish(accept(_,_));
	NewL = [];
	for (.member(X ,Old)) {
		.nth(1, X, Name);
		if (.member(L, [_, Name])) {
			.print(Name);
		}
	}
	.difference(L, Old, X);
	.sort(Old, OldSorted);
	.sort(X, XSorted);
	.print("old is",OldSorted);
	//.print("x is:",XSorted);
	.concat(Old, X, Y);
	.print("Y is:", Y);
	.length(Y, Length);
	//perché???
	Length = Length;
	// nella versione finale i lavoratori verranno ordinati a seconda della loro richiesta di denaro
	for( .range(I, 0, Nwork - 1) ) {
		if( Length > I) {
			.nth(I, Y, Employee);
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

