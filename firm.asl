// Agent firm in project SimpleEconomy.mas2j

/* Initial beliefs and rules */
maxX(300).
maxY(500).

/* Initial goals */

!start.

/* Plans */

+offer(O)[source(S)] <-
	.print("Ho ricevuto l'offerta con valore ",O," dall'agente ",S).

+!start : maxX(MX) & maxY(MY) <-
	!boundRandom(MX, X);
	!boundRandom(MY, Y);
	+coords(X,Y);
	.my_name(Me);
	.broadcast(tell, introduction(Me, X, Y)).

+!boundRandom(BOUND, RES) <-
	.random(T);
	RES = BOUND * T div 1.
