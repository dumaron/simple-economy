maxDemand(5). // massimo numero di curriculum inviabili
maxWage(1000). // stipendio massimo (ahahaha)
minWage(1). // stipendio minimo

!start.

+!start : maxDemand(M) & maxWage(W)<-
	.wait(2000); // necessario perché tutte le Firm si presentino
	.findall(Name, introduction(Name), Firms);
	+firmList(Firms);
	!boundRandom(W, Wage);
	+requiredWage(Wage);
	!sendDemands.

// Indichiamo al lavoratore che è iniziato un nuovo ciclo di mercato 
+beginCycle <-
	-beginCycle;
	-unemployed; // almeno c'è la buona volontà
	!sendDemands.
	
+!sendDemands : firmList(L) & maxDemand(M) & oldFirm(Old) <-
	!sendDemand(L, M, Old).

+!sendDemands : firmList(L) & maxDemand(M) & not oldFirm(Old) <-
	!sendDemand(L, M).
	
// Piano per inviare una richiesta al vecchio datore di lavoro
+!sendDemand(L, M, Old) : requiredWage(Wage) <-
	.delete(Old, L, ReducedL);
	.my_name(Me);
	.send(Old, tell, demand(Me, Wage));
	!sendDemand(ReducedL, M-1).

// Piano per inviare una richiesta di lavoro agli imprenditori che conosco, 
// sempre entro i limiti di maxDemand
+!sendDemand(Firms, Count) : requiredWage(Wage) <-
	.length(Firms, NumFirms);
	if (Count>0 & NumFirms>0) { 
		// seleziono un'azienda a caso fra quelle che conosco
		!boundRandom(NumFirms-1, Random);
		.nth(Random, Firms, Firm);
		.my_name(Me);
		.send(Firm, tell, demand(Me, Wage));
		.delete(Random, Firms, ReducedFirms);
		!sendDemand(ReducedFirms, Count-1);
	}
	else {
		// per questo agente la fase del ciclo in cui si inviano curriculum
		// è terminata
		sentAllDemand;
	}.

// piano per generare un intero casuale limitato superiorimente da Bound	
+!boundRandom(Bound, Result) <-
	.random(R);
	Result = math.round(Bound * R).

+!chooseNewFirm <-
	.findall(Firm, jobOffer(Firm), Firms);
	.abolish(jobOffer(_));
	.length(Firms, NumFirms);
	// se ho almeno una richiesta di lavoro...
	if (NumFirms>0) {
		// lavoro per il primo che mi ha risposto
		.nth(0, Firms, ChoosedFirm);
		!startWork(ChoosedFirm);
	} else {
		// altrimenti sono disoccupato
		+unemployed;
	}.

// credenza attivata quando le aziende hanno inviato le loro richieste e nel
// ciclo precedente ero disoccupato
+jobOfferOver : not oldFirm(F) <-
	!chooseNewFirm.

// credenza attivata quando le aziende hanno inviato le loro richieste e nel
// ciclo precedente ero occupato
+jobOfferOver : oldFirm(Old) <-
	.findall(Firm, jobOffer(Firm), Firms);
	.abolish(jobOffer(_));
	.length(Firms, Length);
	if( .member(Old, Firms) ) {
		// torno a lavorare per il mio vecchio datore di lavoro solo se ha 
		// rinnovato la sua richiesta nei miei confronti
		!startWork(Old);
	}
	else {
		// se non rinnova la richiesta, provo con gli altri datori
		!chooseNewFirm;
	}.

+unemployed : requiredWage(W) & minWage(WageLowerBound)<- 
	// informo l'environment che per questo ciclo sono disoccupato
	unemployed;
	// abbasso il mio stipendio, usando come limite inferiore minWage
	!boundRandom(W - WageLowerBound, UpdWage);
	-+requiredWage(W - UpdWage).
	
+!startWork(Firm) : requiredWage(W) & maxWage(WageBound) <-
	// informo l'azienda che accetto
	.my_name(Me);
	.print(Me,": accepting job from", Firm);
	.send(Firm, tell, accept(Me,W));
	// informo l'environment che per questo ciclo sono occupato
	employed;
	// alzo lo stipendio!!
	!boundRandom(WageBound - W, UpdWage);
	-+requiredWage(W + UpdWage);
	-+oldFirm(Firm).

