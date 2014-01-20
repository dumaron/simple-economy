import jason.asSyntax.*;
import jason.environment.*;
import java.lang.Integer;
import java.util.List;
import java.util.ArrayList;
import java.util.logging.Logger;


public class world extends Environment {
	// any class members needed...
	
	Integer nfirm, nworkers;
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
		workers=new ArrayList<String>();
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
		
		//logger.info("received act from: "+ag);
		
		
		if(act.getFunctor().equals("sentAllOffers")) {
			workers.add(ag);
			//logger.info("nworkers: "+nworkers);
			if(workers.size() == nworkers) {
				addPercept(Literal.parseLiteral("offersOver"));
			}
		}
		return true;
	}
	
}

