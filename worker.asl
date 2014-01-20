// Agent worker in project SimpleEconomy.mas2j

/* Initial beliefs and rules */
maxOffer(5).

/* Initial goals */

!start.

/* Plans */

+!start : maxOffer(M)<-
	.wait(2000);
	.findall(Name, introduction(Name), L);
	+firmList(L);
	!sendOffers(L, M).

+!sendOffers(L, M) <-
	if (M>0) { 
		.length(L, Length);
		!boundRandom(Length-1, Random);
		if (Length > 0) {
			.my_name(Me);
			.nth(Random, L, Firm);
			.send(Firm, tell, offer(Me));
			.delete(Random, L, LA);
			!sendOffers(LA, M-1);
		}
		else {
			sentAllOffers;
		}
	}
	else {
		sentAllOffers;
	}.
	
+!boundRandom(BOUND, RES) <-
	.random(T);
	RES = math.round(BOUND * T).
	
+offersOver <-
	print("offers over").
	

