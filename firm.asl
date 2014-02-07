maxProduction(27).
productionCoefficient(3).
goods(0).
capital(10000).

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
	.print("nworkers", Nwork);
	// mi presento a tutti gli altri agenti
	.my_name(Me);
	.broadcast(tell, introduction(Me)).

// credenza che indica una nuova fase del ciclo, in cui tutti i curriculum
// sono stati inviati dai lavoratori
+demandOver <-
	.findall([W, Worker], demand(Worker,W), NewDemandsList);
	+demands(NewDemandsList);
	.findall(Employed, accept(Employed, W), OldEmployedList);
	.abolish(demand(_,_));
	.abolish(accept(_,_));
	//.print(OldEmployedList);
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
	
	//.print("needed work is", Nwork);
	//.print("La lista dei vecchi è ", OldEmployedDemandsList);
	//.print("La lista corretta è ", Demands);
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
	//.print(Me, ": sending job offer to", WorkerName);
	.send(WorkerName, tell, jobOffer(Me));
	.send(WorkerName, askOne, jobOffer(Me), UnusedRes).

// credenza attivata nella fase del ciclo in cui esso termina
+jobMarketClosed : neededWorkers(N) & productionCoefficient(C) & goods(G) <-
	.findall(E, accept(E, W), L);
	.length(L, Employed);
	// informo l'environment sul mio dato occupazionale, così da avere al
	// prossimo ciclo una probabilità di trovare lavoratori proporzionale a 
	// questo valore
	.abolish(introduction(_));
	Production = Employed * C;
	-+goods(Production + G);
	.print("production is: ", Production, "old goods are", G);
	endCycle(N - Employed).

