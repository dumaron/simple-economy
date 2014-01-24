// Agent worker in project SimpleEconomy.mas2j

/* Initial beliefs and rules */
maxDemand(5).
maxWage(1000).
/* Initial goals */

!start.

/* Plans */

+!start : maxDemand(M) & maxWage(W)<-
	.wait(2000);
	.findall(Name, introduction(Name), L);
	+firmList(L);
	!boundRandom(W, Wage);
	+requiredWage(Wage);
	!sendDemands.

+beginCycle <-
	-beginCycle;
	!sendDemands.
	
+!sendDemands : firmList(L) & maxDemand(M) <-
	!sendDemand(L,M).

+!sendDemand(L, M) : requiredWage(W) <-
	if (M>0) { 
		.length(L, Length);
		!boundRandom(Length-1, Random);
		if (Length > 0) {
			.my_name(Me);
			.nth(Random, L, Firm);
			.send(Firm, tell, demand(Me,W));
			.delete(Random, L, LA);
			!sendDemand(LA, M-1);
		}
		else {
			sentAllDemand;
		}
	}
	else {
		sentAllDemand;
	}.
	
+!boundRandom(BOUND, RES) <-
	.random(T);
	RES = math.round(BOUND * T).

+jobOfferOver : not oldFirm(F) <-
	.findall(Firm, jobOffer(Firm), L);
	.abolish(jobOffer(_));
	.length(L, Length);
	if (Length>0) {
		.nth(0, L, ChoosedFirm);
		!startWork(ChoosedFirm);
	} else {
		//.print("Io rimango disoccupato, per ora");
		unemployed;
	}
	.

+jobOfferOver : oldFirm(F) <-
	.findall(Firm, jobOffer(Firm), L);
	.abolish(jobOffer(_));
	//.print("Mi sono state fatte offerte di lavoro da ",L);
	.length(L, Length);
	if( .member(F, L) ) {
		!startWork(F);
	}
	else {
	if (Length>0) {
		.nth(0, L, ChoosedFirm);
		!startWork(ChoosedFirm);
	}
	else {
		//.print("Io rimango disoccupato, per ora");
		unemployed;
		.abolish(oldFirm(_));
	}
	}
	.

+!startWork(Firm) : requiredWage(W) <-
	.my_name(Me);
	.send(Firm, tell, accept(Me,W));
	employed;
	-+oldFirm(Firm).

