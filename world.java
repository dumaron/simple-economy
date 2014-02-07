import jason.asSyntax.*;
import jason.environment.*;
import java.lang.Integer;
import java.util.List;
import java.util.ArrayList;
import java.util.logging.Logger;
import java.io.FileInputStream;
import jason.mas2j.*;


public class world extends Environment {
	// any class members needed...
	
	Integer nfirm, nworkers, employed, unemployed, cycle=1, firmCount, workerCount;
	List<String> firms;
	List<String> workers;
	
    static Logger logger = Logger.getLogger(world.class.getName());

	
	@Override
	public void init(String[] args) {
		workers=new ArrayList<String>();
		firms = new ArrayList<String>();
		try {
			jason.mas2j.parser.mas2j parser = new jason.mas2j.parser.mas2j(new FileInputStream(args[0]));
			MAS2JProject project = parser.mas();
			for (AgentParameters ap : project.getAgents()) {
				if (ap.name.equals("firm")) {
					for (int i=1; i<=ap.qty; i++) {
						firms.add("firm"+i);
					}
				} else {
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
		
		if(act.getFunctor().equals("sentAllDemand")) {
			if(++workerCount == workers.size()) {
				workerCount = 0;
				removePerceptToList(workers, "beginCycle", false);
				addPerceptToList(firms, "demandOver");
			}
		}
		else if (act.getFunctor().equals("sentAllJobOffer")) {
			if (++firmCount == firms.size()) {
				firmCount = 0;
				addPerceptToList(workers, "jobOfferOver");	
			}
		}
		else if (act.getFunctor().equals("unemployed")) {
			unemployed++;
		}
		else if (act.getFunctor().equals("employed")) {
			employed++;
		}
		else if (act.getFunctor().equals("endJobCycle")) {
			Integer probab, i, production;
			probab=Integer.parseInt(act.getTerm(0).toString());
			production=Integer.parseInt(act.getTerm(1).toString());
			for(i=0; i<=probab; i++) {
				addPerceptToList(workers, "firmVacancies("+ag+","+i+")");
			}
			for(i=0; i<production; i++) {
				addPerceptToList(workers, "firmProduction("+ag+","+i+")");
			}
			if (++firmCount == firms.size()) {
				removePerceptToList(firms, "jobMarketClosed", false);
				firmCount = 0;
				addPerceptToList(workers, "startGoodsMarket");
			}
		} else if (act.getFunctor().equals("introduced")) {
			if (++firmCount == firms.size()) {
				firmCount = 0;
				addPerceptToList(workers, "firstCycle");
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

