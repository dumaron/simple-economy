// Agent firm in project SimpleEconomy.mas2j

/* Initial beliefs and rules */

/* Initial goals */

!start.

/* Plans */

+offersOver <-
	!chooseWorkers.
	
+!start <-
	.my_name(Me);
	!boundRandom(9,N);
	+neededWorkers(N);
	.broadcast(tell, introduction(Me)).

+!boundRandom(BOUND, RES) <-
	.random(T);
	RES = math.round(BOUND * T +1).

+!chooseWorkers : neededWorkers(Nwork) <-
	.findall(Worker, offer(Worker), L);
	.length(L, Length);
	for( .range(I, 0, Nwork - 1) ) {
			if(I <= Lenght) {
				.nth(I, L, Employee);
				//+employed(Employee);
				.print(Employee);
	}
	}.
	
	
