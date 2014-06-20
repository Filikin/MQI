trigger CreateUpdateCarePlanStepOnEvent on Event (after insert, after update) 
{
	// need to know what a care plan objective looks like, if none, then we can leave
	String carePlanObjectiveIdentifier='';
	List<Care_Plan_Objective__c>cpo = new List<Care_Plan_Objective__c>();
	cpo = [select id from Care_Plan_Objective__c limit 1];
	if (cpo.size() > 0) carePlanObjectiveIdentifier=((String)(cpo[0].id)).substring(0,3);
	else return;
	
	List <Event>events = [select ID, WhatID, StartDateTime, Care_plan_step_description__c from Event where ID in :trigger.newMap.keySet()];

 	List <Care_plan_step__c>newSteps = new List<Care_plan_step__c>();
	
	List <Care_plan_step__c>currentSteps = [select ID, Date__c, Description__c, Reference__c from Care_plan_step__c where Reference__c in :trigger.newMap.keySet()];
	Map <ID, Care_plan_step__c>currentStepsMap = new Map<ID, Care_plan_step__c>();
	for (Care_plan_step__c oneStep: currentSteps)
	{
		currentStepsMap.put (oneStep.Reference__c, oneStep);
	}
		
			
	for (Event oneEvent: events)
	{
		if (oneEvent.WhatId != null && ((String)(oneEvent.WhatId)).startsWith (carePlanObjectiveIdentifier))
		{
			if (trigger.isInsert)
			{
				Care_plan_step__c oneStep = new Care_plan_step__c (Care_Plan_Objective__c=oneEvent.whatID,
					Date__c=oneEvent.StartDateTime.Date(), Description__c=oneEvent.Care_plan_step_description__c, Reference__c=oneEvent.id);
				newSteps.Add(oneStep);
			}
			else
			{
				Care_plan_step__c oneStep = currentStepsMap.get (oneEvent.id);
					oneStep.Date__c=oneEvent.StartDateTime.Date();
					oneStep.Description__c=oneEvent.Care_plan_step_description__c;
			}
		}		
	}
	if (newSteps.size() > 0) insert newSteps;
	if (currentSteps.size()> 0) update currentSteps;

}