maxDemand(5). // massimo numero di curriculum inviabili
maxWage(1000). // stipendio massimo (ahahaha)
minWage(1). // stipendio minimo
money(1000).
maxSellers(5).

// piano per generare un intero casuale limitato superiorimente da Bound	
+!boundRandom(Bound, Result) <-
	.random(R);
	Result = math.round(Bound * R).

+?introduction(Source) <- 
	+introduction(Source).

+firstCycle : maxDemand(M) & maxWage(W)<-
	.findall(Name, introduction(Name), Firms);
	.abolish(introduction(_));
	+firmList(Firms);
	+expenses(0);
	!boundRandom(W, Wage);
	+requiredWage(Wage);
	!sendAllDemands.

// Indichiamo al lavoratore che è iniziato un nuovo ciclo di mercato 
+beginCycle <-
	-unemployed; // almeno c'è la buona volontà
	!buryDeads;
	!respawn;
	.findall(Firm, firmVacancies(Firm, N), FirmVac);
	-+firmList(FirmVac);
	!sendAllDemands.
	
+!buryDeads <-
	.findall(Firm, dead(Firm), Deads);
	.findall(Firm, firmVacancies(Firm, N), FirmVac);
	!bury(Deads).

+!bury([Dead | Tail]) <-
	.abolish(firmVacancies(Dead,_));
	!bury(Tail).

+!bury([]).
	
+!respawn <-
	.findall(Firm, respawned(Firm), LRespawn);
	.abolish(respawned(_));
	.abolish(dead(_));
	!respawnFirm(LRespawn).

+!respawnFirm([Firm | Tail]) <-
	-introduction(Firm);
	+firmVacancies(Firm, 1);
	!respawnFirm(Tail).
	
+!respawnFirm([]).

+!sendAllDemands : firmList(L) & maxDemand(M) & oldEmployer(Old) & .member(Old, L) <-
	!sendDemand(L, M, Old).

+!sendAllDemands : firmList(L) & maxDemand(M) <-
	!sendDemand(L, M).
	
// Piano per inviare una richiesta al vecchio datore di lavoro
+!sendDemand(L, M, Old) : requiredWage(Wage) <-
	.delete(Old, L, ReducedL);
	.my_name(Me);
	.send(Old, askOne, jobRequest(Me, Wage), Unused);
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
		.send(Firm, askOne, jobRequest(Me,Wage), Unused);
		.delete(Firm, Firms, ReducedFirms);
		!sendDemand(ReducedFirms, Count-1);
	}
	else {
		// per questo agente la fase del ciclo in cui si inviano curriculum
		// è terminata
		sentAllDemand;
	}.

+!chooseEmployer([]) <-
	+unemployed.

+!chooseEmployer([Firm | Tail]) <-
	!startWork(Firm).

+?jobOffer(Firm) <-
	+jobOffer(Firm).
	
// credenza attivata quando le aziende hanno inviato le loro richieste e nel
// ciclo precedente ero disoccupato
+jobOfferOver : not oldEmployer(F) <-
	.findall(Firm, jobOffer(Firm), Firms);
	.abolish(jobOffer(_));
	.findall(Firm, jobOffer(Firm), Firms2);
	!chooseEmployer(Firms).

// credenza attivata quando le aziende hanno inviato le loro richieste e nel
// ciclo precedente ero occupato
+jobOfferOver : oldEmployer(Old) <-
	.findall(Firm, jobOffer(Firm), Firms);
	.abolish(jobOffer(_));
	if( .member(Old, Firms) ) {
		// torno a lavorare per il mio vecchio datore di lavoro solo se ha 
		// rinnovato la sua richiesta nei miei confronti
		!startWork(Old);
	}
	else {
		// se non rinnova la richiesta, provo con gli altri datori
		!chooseEmployer(Firms);
	}.

+unemployed : requiredWage(W) & minWage(WageLowerBound) <- 
	// abbasso il mio stipendio, usando come limite inferiore minWage
	!boundRandom(W - WageLowerBound, UpdWage);
	-+requiredWage(W - UpdWage);
	// informo l'environment che per questo ciclo sono disoccupato
	unemployed.

+?pay(Wage) : money(M) <-
	-+money(M+Wage).
	
+startGoodsMarket : maxSellers(NSellers) <-
	-+expenses(0);
	.findall([Price, Firm], firmProduction(Firm, Price, Production), LProd);
	!chooseSeller(LProd, NSellers, []).

+!chooseSeller(LProd, NSellers, ChosenSellers) : bestPrice([P,F]) & (LProd==[] | NSellers==0) <-
	.sort(ChosenSellers, SortedSellers);
	if(.member([_,F], SortedSellers)) {
		.delete([_,F], SortedSellers, RemovedL);
	}
	else {
		.length(SortedSellers, L);
		.delete(L, SortedSellers, RemovedL);
	}
	.concat([[P,F]] ,RemovedL, FinalSellers);
	.nth(0, SortedSellers, LowestPrice);
	-+bestPrice(LowestPrice);
	-+chosenSellers(FinalSellers);
	!buy.

+!chooseSeller(LProd, NSellers, ChosenSellers) : LProd==[] | NSellers==0 <-
	.sort(ChosenSellers, SortedSellers);
	.nth(0, SortedSellers, LowestPrice);
	-+bestPrice(LowestPrice);
	-+chosenSellers(ChosenSellers);
	!buy.

+!chooseSeller(LProd, NSellers, ChoosedSellers) <-
	.length(LProd, NProd);
	!boundRandom( NProd-1, Idx);
	.nth(Idx, LProd, Seller);
	//ask seller
	.delete(Seller, LProd, UpdLProd);
	.concat(ChoosedSellers, [Seller], NewSellers);
	!chooseSeller(UpdLProd, NSellers - 1, NewSellers).

+!startWork(Firm) : requiredWage(W) & maxWage(WageBound) <-
	// informo l'azienda che accetto
	.my_name(Me);
	.send(Firm, askOne, jobAccept(Me, W), UnusedRes);
	!boundRandom(WageBound - W, UpdWage);
	-+requiredWage(W + UpdWage); // alzo lo stipendio!!
	-+oldEmployer(Firm);
	// informo l'environment che per questo ciclo sono occupato
	employed.

+!buy : (money(0) | chosenSellers([])) & expenses(E) <-
	goodsMarketClosed(E).


+!buy : money(Money) & chosenSellers([[Price, Seller] | Tail]) & firmList(Firms)  <-
	-+chosenSellers(Tail);
	if (.member(Seller, Firms)) { 
		.send(Seller, tell, buy(Money));
	} else {
		!buy;
	}.

+sold(Goods, Price)[source(S)] :  money(Money) & expenses(E) <-
	-sold(Goods, Price)[source(S)];
	-+money(Money - (Goods * Price));
	-+expenses(E + (Goods * Price));
	!buy.
