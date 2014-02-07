maxDemand(5). // massimo numero di curriculum inviabili
maxWage(1000). // stipendio massimo (ahahaha)
minWage(1). // stipendio minimo
money(100).
maxSellers(5).

+?introduction(Source) <- 
	+introduction(Source).

+firstCycle : maxDemand(M) & maxWage(W)<-
	.findall(Name, introduction(Name), Firms);
	.abolish(introduction(_));
	+firmList(Firms);
	!boundRandom(W, Wage);
	+requiredWage(Wage);
	!sendDemands.

// Indichiamo al lavoratore che è iniziato un nuovo ciclo di mercato 
+beginCycle <-
	-beginCycle;
	-unemployed; // almeno c'è la buona volontà
	.findall(Firm, firmVacancies(Firm, N), FirmVac);
	-+firmList(FirmVac);
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
	.send(Old, askOne, demand(Me,Wage), Unused);
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
		//.send(Firm, tell, demand(Me, Wage));
		.send(Firm, askOne, demand(Me,Wage), Unused);
		.delete(Firm, Firms, ReducedFirms);
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

+!chooseNewFirm(Firms) <-
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

+?jobOffer(Firm) <- 
	+jobOffer(Firm).
	
// credenza attivata quando le aziende hanno inviato le loro richieste e nel
// ciclo precedente ero disoccupato
+jobOfferOver : not oldFirm(F) <-
	.findall(Firm, jobOffer(Firm), Firms);
	.abolish(jobOffer(_));
	!chooseNewFirm(Firms).

// credenza attivata quando le aziende hanno inviato le loro richieste e nel
// ciclo precedente ero occupato
+jobOfferOver : oldFirm(Old) <-
	.findall(Firm, jobOffer(Firm), Firms);
	if( .member(Old, Firms) ) {
		// torno a lavorare per il mio vecchio datore di lavoro solo se ha 
		// rinnovato la sua richiesta nei miei confronti
		!startWork(Old);
	}
	else {
		// se non rinnova la richiesta, provo con gli altri datori
		!chooseNewFirm(Firms);
	}.

+unemployed : requiredWage(W) & minWage(WageLowerBound) <- 
	// abbasso il mio stipendio, usando come limite inferiore minWage
	!boundRandom(W - WageLowerBound, UpdWage);
	-+requiredWage(W - UpdWage);
	// informo l'environment che per questo ciclo sono disoccupato
	unemployed.

+?pay(Wage) : money(M) <-
	-+money(M+Wage).
	//.print("Got money ", M+Wage).

+startGoodsMarket : maxSellers(NSellers) <-
	.findall(Firm, firmProduction(Firm, Production), LProd);
	//.print(L);
	!chooseSeller(LProd, NSellers).

+!chooseSeller([], NSellers) <-
	.print("Scelto Negozi").

+!chooseSeller(LProd, NSellers) : oldSeller(S) & .member(S, LProd) <-
	//ask seller
	.delete(S, LProd, UpdLProd);
	!chooseSeller(UpdLprod, NSellers-1).

+!chooseSeller(LProd, NSellers) : NSellers >0 <-
	.length(LProd, NProd);
	!boundRandom( NProd-1, Idx);
	.print("Idx is ", Idx);
	.nth(Idx, LProd, Seller);
	//ask seller
	.print("Selezionato negozio ", Seller);
	.delete(Seller, LProd, UpdLProd);
	!chooseSeller(UpdLProd, NSellers - 1).


+!startWork(Firm) : requiredWage(W) & maxWage(WageBound) <-
	// informo l'azienda che accetto
	.my_name(Me);
	//.print(Me,": accepting job from", Firm);
	.send(Firm, askOne, accept(Me, W), UnusedRes);
	// alzo lo stipendio!!
	!boundRandom(WageBound - W, UpdWage);
	-+requiredWage(W + UpdWage);
	-+oldFirm(Firm);
	// informo l'environment che per questo ciclo sono occupato
	employed.

