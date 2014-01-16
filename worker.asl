// Agent worker in project SimpleEconomy.mas2j

/* Initial beliefs and rules */
maxX(300).
maxY(500).
maxOffer(5).
maxRadius(100).

/* Initial goals */

!start.

/* Plans */

+!start : maxX(MX) & maxY(MY) <-
	!boundRandom(MX, X);
	!boundRandom(MY, Y);
	+coords(X,Y);
	.wait(2000);
	.findall([Name, FX, FY], introduction(Name ,FX, FY), L);
	+firmList(L);
	!sendOffers.

+!sendOffers : firmList(L) & maxRadius(MR) <- 
	for (.member(X,L)) {
		.nth(0,X,Name);
		if (Name == firm1) {
			.print("Idoli");
		}
	}.
	
+!boundRandom(BOUND, RES) <-
	.random(T);
	RES = BOUND * T div 1.
