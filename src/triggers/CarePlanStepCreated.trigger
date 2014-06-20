trigger CarePlanStepCreated on Care_plan_step__c (after insert) 
{
	Set<ID>carePlanObjectiveIDs = new Set<ID>();
	for (Care_plan_step__c oneStep: trigger.new)
	{
		if (oneStep.Care_Plan_Objective__c != null)
		{
			carePlanObjectiveIDs.add (oneStep.Care_Plan_Objective__c);
		} 
	}
	Map<ID, Care_Plan_Objective__c>carePlanObjectiveMap = new Map<ID, Care_Plan_Objective__c>([select ID, Care_plan_step_count__c from Care_Plan_Objective__c where ID in :carePlanObjectiveIDs]);
	
	for (Care_plan_step__c oneStep: trigger.new)
	{
		if (oneStep.Care_Plan_Objective__c != null)
		{
			Care_Plan_Objective__c oneObjective = carePlanObjectiveMap.get(oneStep.Care_Plan_Objective__c);
			if (oneObjective.Care_plan_step_count__c == null) oneObjective.Care_plan_step_count__c = 1;
			else oneObjective.Care_plan_step_count__c++;
		}
	}
	update carePlanObjectiveMap.values();
}