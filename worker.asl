// Agent worker in project SimpleEconomy.mas2j

/* Initial beliefs and rules */
maxDemand(5).

/* Initial goals */

!start.

/* Plans */

+!start : maxDemand(M)<-
	.wait(2000);
	.findall(Name, introduction(Name), L);
	+firmList(L);
	!sendDemands(L, M).

+!sendDemands(L, M) <-
	if (M>0) { 
		.length(L, Length);
		!boundRandom(Length-1, Random);
		if (Length > 0) {
			.my_name(Me);
			.nth(Random, L, Firm);
			.send(Firm, tell, demand(Me));
			.delete(Random, L, LA);
			!sendDemands(LA, M-1);
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
	
+jobOfferOver <-
	.findall(Firm, jobOffer(Firm), L);
	//.print("Mi sono state fatte offerte di lavoro da ",L);
	.length(L, Length);
	if (Length>0) {
		.nth(0, L, ChoosedFirm);
		!startWork(ChoosedFirm);
	} else {
		//.print("Io rimango disoccupato, per ora");
		unemployed;
	}
	.

+!startWork(Firm) <-
	//.send(Firm, tell, accept);
	employed.

