import jason.asSyntax.*;
import jason.environment.*;
import java.lang.Integer;
import java.util.List;
import java.util.ArrayList;
import java.util.Collection;
import java.util.logging.Logger;
import java.io.FileInputStream;
import jason.mas2j.*;
import jason.runtime.Settings;



public class world extends Environment {
	// any class members needed...
	
	Integer nfirm, nworkers, employed, unemployed, cycle=1, firmCount, 
	workerCount, currAggrPrice=0, oldAggrPrice, bankrupt, business, toRespawn, totalProduction, totalIncome, totalProbab;
	List<String> firms;
	List<String> workers;
	List<String> deadFirms;
	List<String> respawnNext;
	Boolean firstCycle=true;
	
    static Logger logger = Logger.getLogger(world.class.getName());

	
	@Override
	public void init(String[] args) {
		workers=new ArrayList<String>();
		firms = new ArrayList<String>();
		deadFirms = new ArrayList<String>();
		respawnNext = new ArrayList<String>();
		try {
			jason.mas2j.parser.mas2j parser = new jason.mas2j.parser.mas2j(new FileInputStream(args[0]));
			MAS2JProject project = parser.mas();
			for (AgentParameters ap : project.getAgents()) {
				if (ap.name.equals("firm")) {
					for (int i=1; i<=ap.qty; i++) {
						firms.add("firm"+i);
					}
				} else if(ap.name.equals("worker")) {
					for (int i=1; i<=ap.qty; i++) {
						workers.add("worker"+i);
					}
				}
			}
		} catch(Exception e) {
		
		}
		firmCount = new Integer(0);
		workerCount = new Integer(0);
		employed = new Integer(0);
		unemployed = new Integer(0);
		bankrupt = new Integer(0);
		business = new Integer(0);
		toRespawn = new Integer(0);
		totalProduction = new Integer(0);
		totalIncome = new Integer(0);
		totalProbab = 0;
	}
	@Override
	public void stop() {
		// anything else to be done by the environment when
		// the system is stopped...
	}
	
	private void addPerceptToList(List<String> list, String percept) {
		for(String ag : list) {
			addPercept(ag, Literal.parseLiteral(percept));
		}
	}
	
	private void removePerceptToList(List<String> list, String percept, Boolean unif) {
		for(String ag : list) {
			if (!unif)
				removePercept(ag, Literal.parseLiteral(percept));
			else
				removePerceptsByUnif(ag, Literal.parseLiteral(percept));
		}
	}
	private boolean respawn() {
		boolean result = false;
		for (String respawn : respawnNext) {
			logger.info("respawning "+respawn);
			addPercept("creator", Literal.parseLiteral("respawnFirm("+respawn+")"));
			addPerceptToList(workers, "respawned("+respawn+")");
			removePerceptToList(workers, "dead("+respawn+")", false);
			firms.add(respawn);
			result = true;
		}
		return result;
	}
	@Override
	public synchronized boolean executeAction(String ag, Structure act) {
		// this is the most important method, where the
		// effects of agent actions on perceptible properties
		// of the environment is defined
		
		switch (act.getFunctor()) {
			case "sentAllDemand": 
				if(++workerCount == workers.size()) {
					workerCount = 0;
					removePerceptToList(workers, "beginCycle", false);
					addPerceptToList(firms, "jobRequestOver");
				}
				break;
			case "sentAllJobOffer": 
				if (++firmCount == firms.size()) {
					firmCount = 0;
					addPerceptToList(workers, "jobOfferOver");	
				}
				break;
			case "goodsMarketClosed":
				Integer income = Integer.parseInt(act.getTerm(0).toString());
				totalIncome+=income;
				if (++workerCount == workers.size()) {
					workerCount = 0;
					removePerceptToList(workers, "startGoodsMarket", false);
					removePerceptToList(workers, "firmProduction(_,_,_)", true);
					addPerceptToList(firms, "endCycle");
					logger.info("PIL: "+totalIncome);
					totalIncome=0;
				}
				break;
			case "unemployed": unemployed++; break;
			case "employed" : employed++; break;
			case "jobMarketClosed": 
				Integer probab, i, production, price;
				probab=Integer.parseInt(act.getTerm(0).toString());
				production=Integer.parseInt(act.getTerm(1).toString());
				price = Integer.parseInt(act.getTerm(2).toString());
				currAggrPrice+=price;
				
				//addPerceptToList(workers, "firmVacancies("+ag+","+totalProbab+","+(totalProbab + probab)+")");
				addPerceptToList(workers, "firmVacancies("+ag+",0)");
				addPerceptToList(workers, "firmProduction("+ag+","+price+","+totalProduction+","+ (totalProduction+production) +")");
				totalProbab += probab;
				totalProduction += production;
				
				if (++firmCount == firms.size()) {
					currAggrPrice=currAggrPrice/firms.size();
					logger.info("Prezzo aggregato: "+currAggrPrice);
					logger.info("Produzione totale: "+totalProduction);
					removePerceptToList(firms, "oldAggregatePrice(_)", true);
					removePerceptToList(firms, "newAggregatePrice(_)", true);
					removePerceptToList(workers, "totalProd(_)", true);
					removePerceptToList(firms, "jobMarketClosed", false);
					firmCount = 0;
					addPerceptToList(workers, "totalProd("+ totalProduction +")");
					addPerceptToList(firms, "oldAggregatePrice("+oldAggrPrice+")");
					addPerceptToList(firms, "newAggregatePrice("+currAggrPrice+")");
					addPerceptToList(workers, "startGoodsMarket");
					oldAggrPrice=currAggrPrice;
					currAggrPrice=0;
					totalProduction=0;
					totalProbab = 0;
					logger.info("Ma porca...");
				}
				break;
			case "introduced":
				if (firstCycle && ++firmCount == firms.size()) {
					firmCount = 0;
					firstCycle=false;
					addPerceptToList(workers, "firstCycle");
				}
				else if(!firstCycle && ++firmCount == toRespawn) {
					toRespawn = 0;
					firmCount = 0;
					removePerceptsByUnif("creator", Literal.parseLiteral("respawnFirm(_)"));
					addPerceptToList(workers, "beginCycle");
				}
				break;
			case "kill_me": 
				bankrupt++;
				deadFirms.add(ag);
				break;
			case "in_business": business++; break;
		}
		
		if (bankrupt + business == firms.size()) {
			bankrupt = 0;
			business = 0;
			boolean respawned = false;
			removePerceptToList(firms, "endCycle", false);
			removePerceptToList(workers, "respawned(_)", true);
			// risorgo i morti
			respawned = respawn();
			// cancello la lista degli agenti da resuscitare
			toRespawn = respawnNext.size();
			respawnNext.clear();
			// metto i morti nella lista degli agenti da resuscitare
			// e li tolgo dalla lista dei vivi
			for (String dead:deadFirms) {
				addPerceptToList(workers, "dead("+dead+")");
				respawnNext.add(dead);
				firms.remove(dead);
			}
			deadFirms.clear();
			if (firms.isEmpty()) {
				logger.info("Nel ciclo di lavoro "+ cycle++ +" ho 0 occupati e "+workers.size()+" disoccupati");
				respawned = respawn();
				toRespawn = respawnNext.size();
				respawnNext.clear();
			}
			// se non ho resuscitato nessuno...
			if(!respawned){
				addPerceptToList(workers, "beginCycle");
			}
		}
		
		if (employed + unemployed == workers.size()) {
			removePerceptToList(workers, "firmVacancies(_,_)", true);
			logger.info("Nel ciclo di lavoro "+ cycle++ +" ho "+employed+ " occupati e "+unemployed+" disoccupati.");
			employed = unemployed = 0;
			addPerceptToList(firms, "jobMarketClosed");
			removePerceptToList(firms, "jobRequestOver", false);
			removePerceptToList(workers, "jobOfferOver", false);
		}
		return true;
	}
}

