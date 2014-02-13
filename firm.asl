maxProduction(27).
productionCoefficient(3).
goods(0).
capital(10000).
price(50).

!start.

// piano per generare un intero casuale limitato superiorimente da Bound
+!boundRandom(Bound, Result) <-
	.random(R);
	Result = math.round((Bound - 1) * R)+1.
	
+!start : maxProduction(MProd) & productionCoefficient(C) <-
	// imposto un valore intero casuale limitato da 1 e maxWorkers per definire
	// il numero di lavoratori di cui l'azienda ha bisogno
	!boundRandom(MProd, TargProd);
	+targetProduction(TargProd);
	Nwork = TargProd div C;
	+neededWorkers(Nwork);
	// mi presento a tutti gli altri agenti
	.my_name(Me);
	.broadcast(askOne, introduction(Me));
	introduced.

+?demand(Worker, Wage) <- 
	+demand(Worker, Wage).

// credenza che indica una nuova fase del ciclo, in cui tutti i curriculum
// sono stati inviati dai lavoratori
+demandOver <-
	.findall([W, Worker], demand(Worker,W), NewDemandsList);
	+demands(NewDemandsList);
	.findall(Employed, accept(Employed, Wage), OldEmployedList);
	.abolish(demand(_,_));
	.abolish(accept(_,_));
	!updateWages(NewDemandsList, OldEmployedList, []).

// piano per implementare la fedeltà dell'azienda verso il lavoratore
// restituisce una lista dei vecchi impiegati con la loro nuova richeista di stipendio
+!updateWages(New, Old, Res) <-
	.length(New, NewLength);
	NewLength = NewLength; // ??
	if (NewLength > 0) {
		.nth(0, New, NewDemand);
		.delete(0, New, TailNew);
		.nth(1, NewDemand, NewDemandName);
		if (.member(NewDemandName, Old)) {
			.concat([NewDemand], Res, NewRes);
			!updateWages(TailNew, Old, NewRes);
		} else {
			// questa possibilità si verifica in caso di calo della domanda di lavoro
			!updateWages(TailNew, Old, Res);
		}
	}
	else {
		// ultima esecuzione del piano per il ciclo in corso
		.sort(Res, SortedRes);
		!chooseWorkers(SortedRes);
	}
	.

+!chooseWorkers(OldEmployedDemandsList) : neededWorkers(Nwork) & demands(DemandsList) <-
	-demands(DemandsList);
	.difference(DemandsList, OldEmployedDemandsList, NewEmployedDemandsList);
	.sort(NewEmployedDemandsList, SortedNEDL);
	.concat(OldEmployedDemandsList, SortedNEDL, Demands);
	// la lista Demands contiene prima i vecchi impiegati ordinati secondo la
	// loro nuova richiesta di stipendio, poi i disoccupati a loro volta
	// ordinati secondo questo criterio

	.length(Demands, Length);
	Length = Length;	// ??
	// rispondo solo se sono entro al mio numero di lavoratori richiesti e se 
	// ho altre richieste di lavoro
	for( .range(I, 0, Nwork - 1) ) {
		if( Length > I) {
			.nth(I, Demands, Employee);
			!employ(Employee);
		}
	}
	// la fase del ciclo in cui si mandano risposte ai curriculum è terminata
	sentAllJobOffer.

// Piano per richiedere l'assunzione di un impegato
+!employ(E) <-
	.nth(1, E, WorkerName);
	.my_name(Me);
	.send(WorkerName, askOne, jobOffer(Me), UnusedRes).

+?accept(Worker, Wage) <-
	+accept(Worker, Wage).

+!payEmployed([]) <-
	.random(T).

+!payEmployed([[Employed, Wage]|Tail]) : capital(C) <-
	.send(Employed, askOne, pay(Wage), W);
	-+capital(C - Wage);
	!payEmployed(Tail).
	
// credenza attivata nella fase del ciclo in cui esso termina
+jobMarketClosed : neededWorkers(N) & productionCoefficient(C) & goods(G) & price(Price) <-
	.findall([Worker, Wage], accept(Worker, Wage), L);
	.length(L, Employed);
	// informo l'environment sul mio dato occupazionale, così da avere al
	// prossimo ciclo una probabilità di trovare lavoratori proporzionale a 
	// questo valore
	.abolish(introduction(_));
	Production = Employed * C;
	-+goods(Production + G);
	!payEmployed(L);
	endJobCycle(N - Employed, Production, Price).

@buy1[atomic]
+buy(Money)[source(Worker)] : price(Price) & goods(Goods) <-
	//-buy(Money)[source(Worker)];
	.abolish(buy(Money)[source(Worker)]);
	NumGoods = Money div Price;
	.min([Goods, NumGoods], SoldGoods);
	-+goods(Goods-SoldGoods);
	.send(Worker, tell, sold(SoldGoods, Price)).



