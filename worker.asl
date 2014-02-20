maxDemand(3). // massimo numero di curriculum inviabili
maxWage(1000). // stipendio massimo (ahahaha)
minWage(1). // stipendio minimo
money(1000).
maxSellers(3).

+firmPercVacancies(Firm, SV, EV) <-
	+firmVacancies(Firm, SV, EV).
	
+totalPercVac(TV) <-
	-+totalVac(TV).

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
	.findall(Firm, firmVacancies(Firm, SV, EV), FirmVac);
	-+firmList(FirmVac);
	.abolish(firmProduction(_,_,_,_));
	//.print(FirmVac);
	!sendAllDemands.
	
+!buryDeads <-
	.findall(Firm, dead(Firm), Deads);
	!bury(Deads).

+!bury([Dead | Tail]) <-
	.abolish(firmVacancies(Dead,_,_));
	!bury(Tail).

+!bury([]).
	
+!respawn <-
	.findall(Firm, respawned(Firm), LRespawn);
	.abolish(respawned(_));
	.abolish(dead(_));
	!respawnFirm(LRespawn).

+!respawnFirm([Firm | Tail]) : totalProb(P) <-
	-introduction(Firm);
	-+totalProb(P+1);
	+firmVacancies(Firm, P, P+1);
	!respawnFirm(Tail).
	
+!respawnFirm([]).

+!sendAllDemands : firmList(L) & maxDemand(M) & oldEmployer(Old) & .member(Old, L) <-
	!sendDemand(M, Old).

+!sendAllDemands : firmList(L) & maxDemand(M) <-
	!sendDemand(M).
	
// Piano per inviare una richiesta al vecchio datore di lavoro
+!sendDemand(NumFirms, Old) : requiredWage(Wage) & totalVac(TV) <-
	.findall([Old,S,E], firmVacancies(Old, S, E), FVac);
	.nth(0, FVac, OldFirm);
	.nth(1, OldFirm, OldStart);
	.nth(2, OldFirm, OldEnd);
	Delta= OldEnd-OldStart;
	.abolish(firmVacancies(Old,_,_));
	//.print("updating ", OldStart, ", ", OldEnd, ", ", Delta);
	!updateFirmVacList(Delta, OldEnd);
	-+totalVac(TV-Delta);
	.my_name(Me);
	.send(Old, askOne, jobRequest(Me, Wage), Unused);
	!sendDemand(NumFirms-1).

// Piano per inviare una richiesta di lavoro agli imprenditori che conosco, 
// sempre entro i limiti di maxDemand
+!sendDemand(NumFirms) : totalVac(TV) <-
	//.print("sendDemand!!");
	//.print("Total vac", TV);
	if (NumFirms>0 & TV>0) {
		.findall([Firm, SV, EV], firmVacancies(Firm, SV, EV), FirmVac);
		//.print("firm vac, ", FirmVac);
		//.print("send demands to ", FirmVac, "NumFirms ", NumFirms);
		// seleziono un'azienda a caso fra quelle che conosco
		!boundRandom(TV, Random);
		//.print("random is ", Random);
		!selectDemandFirm(FirmVac,  Random, NumFirms);
	}
	else {
		// per questo agente la fase del ciclo in cui si inviano curriculum
		// è terminata
		//.print("Sending!");
		sentAllDemands;
	}.
	
+!selectDemandFirm([[Firm, SV, EV] | Tail], Idx, NumFirms) : totalVac(TV) & requiredWage(Wage) <-
	if(Idx>SV & Idx <=EV | (Idx==0 & Idx==SV)) {
		.abolish(firmVacancies(Firm, SV, EV));
		Delta=EV - SV;
		//.print("EV is ", EV);
		-+totalVac(TV - Delta);
		.my_name(Me);
		.send(Firm, askOne, jobRequest(Me,Wage), Unused);
		!updateFirmVacList(Delta, EV);
		//.print("----Numfirms ", NumFirms);
		!sendDemand(NumFirms - 1);
	}
	else {
		!selectDemandFirm(Tail, Idx, NumFirms);
	}.
	
+!updateFirmVacList(Delta, EV) <-
	.findall([Firm, SVac, EVac], firmVacancies(Firm, SVac, EVac), FirmVac);
	!updateFirmVac(FirmVac, Delta, EV).

+!updateFirmVac([[Firm, SVac, EVac] | Tail], Delta, EV) <-
	if(SVac >= EV) {
		.abolish(firmVacancies(Firm, SVac, EVac));
		+firmVacancies(Firm, SVac - Delta, EVac - Delta);
	}
	!updateFirmVac(Tail, Delta, EV).

+!updateFirmVac([], Delta, EV).

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

+firmPercProduction(Firm, Price, SP, NP) <-
	+firmProduction(Firm,Price,SP,NP).
	//.findall(F, firmProduction(F,P,S,E), L);
	//.print("Fproduction!!",L).
	
+totalPercProd(TP) <-
	//.print("Updating total prod", TP);
	-+totalProd(TP).


+startGoodsMarket : maxSellers(NSellers) <-
	-+expenses(0);
	!chooseSeller(NSellers, []).

/*+!chooseSeller(NSellers, ChosenSellers) :  not firmProduction(F,P,S,E) & bestPrice([P,F])   <-
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
	.abolish(firmProduction(_,_,_,_));
	-+bestPrice(LowestPrice);
	-+chosenSellers(FinalSellers);
	!buy.*/
	

/*+!chooseSeller(0, ChosenSellers) :  bestPrice([P,F]) <-
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
	.abolish(firmProduction(_,_,_,_));
	-+bestPrice(LowestPrice);
	-+chosenSellers(FinalSellers);
	!buy.*/

+!chooseSeller(NSellers, ChosenSellers) : not firmProduction(Fi,Pr,Se,En) | NSellers==0 <-
	.sort(ChosenSellers, SortedSellers);
	.nth(0, SortedSellers, LowestPrice);
	.abolish(firmProduction(_,_,_,_));
	-+bestPrice(LowestPrice);
	-+chosenSellers(ChosenSellers);
	//.print("Chosen", ChosenSellers);
	!buy.

+!chooseSeller(NSellers, ChosenSellers) : totalProd(TP) <-
	!boundRandom(TP, Idx);
	.findall([Firm, Price, StartP, EndP], firmProduction(Firm, Price, StartP, EndP), Prova);
	//.print(Prova);
	!selectFirm(Prova, Idx, NSellers, ChosenSellers).	

+!selectFirm([[Firm, Price, StartP, EndP] | Tail], Idx, NSellers, ChosenSellers) : totalProd(TP) <-
	if((Idx>StartP & Idx <=EndP) | (Idx==0 & Idx==StartP)) {
		.abolish(firmProduction(Firm,_,_,_));
		Delta = (EndP - StartP);
		-+totalProd(TP - Delta);
		!updateSellerList(Delta, EndP);
		.concat(ChosenSellers, [[Price, Firm]] , NewSellers);
		!chooseSeller(NSellers - 1, NewSellers);
	}
	else{
		!selectFirm(Tail, Idx, NSellers, ChosenSellers)
	}.


+!updateSellerList(Delta, EndP) <-
	.findall([Firm, Price, NStartP, NEndP], firmProduction(Firm, Price, NStartP, NEndP), UpdSellers);
	//-+updatedS(UpdSellers);
	!updateSeller(Delta, UpdSellers, EndP).
	
+!updateSeller(Delta, [ [Firm, Price, StartP, EndP] | Tail], OEndP) <-
	if(OEndP<=StartP){
		.abolish(firmProduction(Firm,_,_,_));
		+firmProduction(Firm, Price, StartP - Delta, EndP - Delta);
	}
	!updateSeller(Delta, Tail,OEndP).

+!updateSeller(Delta, [], OEndP).
	
+!startWork(Firm) : requiredWage(W) & maxWage(WageBound) & money(M) <-
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
		//.print("sending offers: ", Money);
		.send(Seller, tell, buy(Money));
	} else {
		!buy;
	}.

+sold(Goods, Price)[source(S)] :  money(Money) & expenses(E) <-
	-sold(Goods, Price)[source(S)];
	-+money(Money - (Goods * Price));
	-+expenses(E + (Goods * Price));
	!buy.
