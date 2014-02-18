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
	
	Integer nfirm, nworkers, employed, unemployed, cycle=1, firmCount, workerCount, currAggrPrice=0, oldAggrPrice, bankrupt, business, toRespawn;
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
					addPerceptToList(firms, "demandOver");
				}
				break;
			case "sentAllJobOffer": 
				if (++firmCount == firms.size()) {
					firmCount = 0;
					addPerceptToList(workers, "jobOfferOver");	
				}
				break;
			case "goodsMarketClosed": 
				if (++workerCount == workers.size()) {
					workerCount = 0;
					removePerceptToList(workers, "startGoodsMarket", false);
					removePerceptToList(workers, "firmProduction(_,_,_)", true);
					addPerceptToList(firms, "endCycle");
				}
				break;
			case "unemployed": unemployed++; break;
			case "employed" : employed++; break;
			case "endJobCycle": 
				Integer probab, i, production, price;
				probab=Integer.parseInt(act.getTerm(0).toString());
				production=Integer.parseInt(act.getTerm(1).toString());
				price = Integer.parseInt(act.getTerm(2).toString());
				currAggrPrice+=price;
				for(i=0; i<=probab; i++) {
					addPerceptToList(workers, "firmVacancies("+ag+","+i+")");
				}
				for(i=0; i<=production; i++) {
					addPerceptToList(workers, "firmProduction("+ag+","+price+","+i+")");
				}
				if (++firmCount == firms.size()) {
					currAggrPrice=currAggrPrice/firms.size();
					removePerceptToList(firms, "oldAggregatePrice(_)", true);
					removePerceptToList(firms, "newAggregatePrice(_)", true);
					removePerceptToList(firms, "jobMarketClosed", false);
					firmCount = 0;
					addPerceptToList(firms, "oldAggregatePrice("+oldAggrPrice+")");
					addPerceptToList(firms, "newAggregatePrice("+currAggrPrice+")");
					addPerceptToList(workers, "startGoodsMarket");
					oldAggrPrice=currAggrPrice;
					currAggrPrice=0;
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
			for (String respawn : respawnNext) {
				logger.info("respawning "+respawn);
				addPercept("creator", Literal.parseLiteral("respawnFirm("+respawn+")"));
				addPerceptToList(workers, "respawned("+respawn+")");
				removePerceptToList(workers, "dead("+respawn+")", false);
				respawned = true;
				firms.add(respawn);
			}
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
			removePerceptToList(firms, "demandOver", false);
			removePerceptToList(workers, "jobOfferOver", false);
		}
		return true;
	}
}

