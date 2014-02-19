maxDemand(3). // massimo numero di curriculum inviabili
maxWage(1000). // stipendio massimo (ahahaha)
minWage(1). // stipendio minimo
money(1000).
maxSellers(3).

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

+firmPercProduction(Firm, Price, SP, NP) <-
	+firmProduction(Firm,Price,SP,NP).

+totalPercProd(TP) <-
	-+totalProd(TP).

+startGoodsMarket : maxSellers(NSellers) <-
	-+expenses(0);
	!chooseSeller(NSellers, []).

+!chooseSeller(NSellers, ChosenSellers) :  not firmProduction(F,P,S,E) & bestPrice([P,F])   <-
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
	

+!chooseSeller(0, ChosenSellers) :  bestPrice([P,F])  <-
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

+!chooseSeller(NSellers, ChosenSellers) : not firmProduction(F,P,S,E) | NSellers==0 <-
	.findall(Firm, firmProduction(F,P,S,E), L);
	.sort(ChosenSellers, SortedSellers);
	.nth(0, SortedSellers, LowestPrice);
	-+bestPrice(LowestPrice);
	-+chosenSellers(ChosenSellers);
	!buy.

+!chooseSeller(NSellers, ChosenSellers) : totalProd(TP) <-
	!boundRandom(TP, Idx);
	.print("random, ",Idx);
	.findall([Firm, Price, StartP, EndP], firmProduction(Firm, Price, StartP, EndP), Prova);
	!selectFirm(Prova, Idx, NSellers, ChosenSellers).
	/*if(Idx==0) {
		.findall([Price, Firm, StartP, EndP], (firmProduction(Firm, Price, StartP, EndP) & Idx >= StartP & Idx <= EndP), Seller);
	}else {
		.findall([Price, Firm, StartP, EndP], (firmProduction(Firm, Price, StartP, EndP) & Idx > StartP & Idx <= EndP), Seller);
	}
	.print("Seller", Seller);
	.nth(0, Seller, USeller); 
	.nth(0, USeller, UPrice);
	.nth(1, USeller, UFirm);
	.nth(2, USeller, UStartP);
	.nth(3, USeller, UEndP);
	//.print("******", UEndP);
	.abolish(firmProduction(UFirm,_,_,_));
	Delta = (UEndP - UStartP);
	//.print("Delta", Delta);
	//.print("UStartP", UStartP);
	//.print("!!!", Delta);
	-+totalProd(TP-Delta);
	!updateSellerList(Delta, UEndP);
	//.print(Seller);
	.concat(ChosenSellers, [[UPrice, UFirm]] , NewSellers);
	//.print("new sellers: ", NewSellers);
	!chooseSeller(NSellers - 1, NewSellers).*/			

+!selectFirm([[Firm, Price, StartP, EndP] | Tail], Idx, NSellers, ChosenSellers) : totalProd(TP) <-
	if((Idx>StartP & Idx <=EndP) | (Idx==0 & Idx==StartP)) {
		//.print("OKIDOKI");
		.abolish(firmProduction(Firm,_,_,_));
		Delta = (EndP - StartP);
		//.print("Delta", Delta);
		//.print("UStartP", UStartP);
		//.print("!!!", Delta);
		-+totalProd(TP-Delta);
		!updateSellerList(Delta, EndP);
		//.print(Firm, " ", StartP, " ", EndP, " ", Idx);
		.concat(ChosenSellers, [[Price, Firm]] , NewSellers);
		//.print("new sellers: ", NewSellers);
		!chooseSeller(NSellers - 1, NewSellers);
	}
	else{
		!selectFirm(Tail, Idx, NSellers, ChosenSellers)
	}.


+!selectFirm([], Idx, NSellers, NewSellers) <-
	.print("_-------------------------------------");
	!chooseSeller(NSellers, NewSellers).

+!updateSellerList(Delta, EndP) <-
	.findall([Firm, Price, NStartP, NEndP], firmProduction(Firm, Price, NStartP, NEndP) /*& EndP <= NStartP*/, UpdSellers);
	//-+updatedS(UpdSellers);
	!updateSeller(Delta, UpdSellers, EndP).
	/*for(.member([UFirm, UPrice, UStartP, UEndP], UpdSellers)) {
		.abolish(firmProduction(UFirm,_,_,_));
		+firmProduction(UFirm, UPrice, UStartP - Delta, UEndP - Delta);
	}.*/
	
+!updateSeller(Delta, [ [Firm, Price, StartP, EndP] | Tail], OEndP) <-
	if(OEndp<=StartP){
		.abolish(firmProduction(Firm,_,_,_));
		+firmProduction(Firm, Price, StartP - Delta, EndP - Delta);
	}
	!updateSeller(Delta, Tail,OEndP).

+!updateSeller(Delta, [], OEndP).


	
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
