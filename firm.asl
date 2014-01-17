// Agent firm in project SimpleEconomy.mas2j

/* Initial beliefs and rules */

/* Initial goals */

!start.

/* Plans */

+offer[source(S)] <-
	.print("ok").

+!start <-
	.my_name(Me);
	.broadcast(tell, introduction(Me)).

+!boundRandom(BOUND, RES) <-
	.random(T);
	RES = math.round(BOUND * T).
