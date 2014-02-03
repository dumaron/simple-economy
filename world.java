import jason.asSyntax.*;
import jason.environment.*;
import java.lang.Integer;
import java.util.List;
import java.util.ArrayList;
import java.util.logging.Logger;


public class world extends Environment {
	// any class members needed...
	
	Integer nfirm, nworkers, employed, unemployed, cycle=1, firmCount;
	List<String> firms;
	List<String> workers;
	
    static Logger logger = Logger.getLogger(world.class.getName());

	
	@Override
	public void init(String[] args) {
		// setting initial (global) percepts ...
		//addPercept(Literal.parseLiteral("p(a)"));
		// if open-world is begin used, there can be
		// negated literals such as ...
		//addPercept(Literal.parseLiteral("~q(b)"));
		// if this is to be perceived only by agent ag1
		//addPercept("ag1", Literal.parseLiteral("p(a)"));
		nworkers= new Integer(args[0]);
		nfirm= new Integer(args[1]);
		firmCount = new Integer(0);
		employed = new Integer(0);
		unemployed = new Integer(0);
		workers=new ArrayList<String>();
		firms = new ArrayList<String>();
	}
	@Override
	public void stop() {
		// anything else to be done by the environment when
		// the system is stopped...
	}
	@Override
	public synchronized boolean executeAction(String ag, Structure act) {
		// this is the most important method, where the
		// effects of agent actions on perceptible properties
		// of the environment is defined
		
		if(act.getFunctor().equals("sentAllDemand")) {
			workers.add(ag);
			//logger.info("nworkers: "+nworkers);
			if(workers.size() == nworkers) {
				workers.clear();
				// nella versione finale questa credenza verrà assegnata solo alle firm
				removePercept(Literal.parseLiteral("beginCycle"));
				addPercept(Literal.parseLiteral("demandOver"));
			}
		}
		else if (act.getFunctor().equals("sentAllJobOffer")) {
			firms.add(ag);
			if (firms.size() == nfirm) {
				firms.clear();
				// nella versione finale questa credenza verrà assegnata solo ai worker
				addPercept(Literal.parseLiteral("jobOfferOver"));	
			}
		}
		else if (act.getFunctor().equals("unemployed")) {
			unemployed++;
		}
		else if (act.getFunctor().equals("employed")) {
			employed++;
		}
		else if (act.getFunctor().equals("endCycle")) {
			firmCount++;
			if (firmCount.equals(nfirm)) {
				removePercept(Literal.parseLiteral("jobMarketClosed"));
				firmCount = 0;
				addPercept(Literal.parseLiteral("beginCycle"));
			}
		}

		
		if (employed + unemployed == nworkers) {
			logger.info("Nel ciclo di lavoro "+ cycle++ +" ho "+employed+ " occupati e "+unemployed+" disoccupati.");
			employed = unemployed = 0;
			workers.clear();
			firms.clear();
			addPercept(Literal.parseLiteral("jobMarketClosed"));
			removePercept(Literal.parseLiteral("demandOver"));
			removePercept(Literal.parseLiteral("jobOfferOver"));
		}
		return true;
	}
}

