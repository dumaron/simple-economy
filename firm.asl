// Agent firm in project SimpleEconomy.mas2j

/* Initial beliefs and rules */

/* Initial goals */

!start.

/* Plans */
	
+!start <-
	.my_name(Me);
	!boundRandom(9,N);
	//.print("La firm ha in totale ",N," posti di lavoro");
	+neededWorkers(N);
	.broadcast(tell, introduction(Me)).

+!boundRandom(BOUND, RES) <-
	.random(T);
	RES = math.round(BOUND * T +1).

+demandOver <-
	!chooseWorkers.

+!chooseWorkers : neededWorkers(Nwork) <-
	.findall(Worker, demand(Worker), L);
	.length(L, Length);
	// nella versione finale i lavoratori verranno ordinati a seconda della loro richiesta di denaro
	for( .range(I, 0, Nwork - 1) ) {
		if(I < Lenght) {
			.print(I, " - ", Length);
			.nth(I, L, Employee);
			!employ(Employee);
		} else {
			.print("ma porca...");
		}
	}
	sentAllJobOffer;
	.

+!employ(E) <-
	.my_name(Me);
	.send(E, tell, jobOffer(Me)).
	
	
